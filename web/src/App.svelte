<script lang="ts">
  import { onMount, tick } from 'svelte';
  import Terminal from './Terminal.svelte';

  type SectionName = 'dotfiles' | 'brew';
  type PackageTarget = { name: string; kind: string };
  type Change = { name: string; current?: string; available?: string; kind?: string; pinned?: boolean };
  type Inventory = {
    changes?: Change[];
    revision?: string;
    upstream?: string;
    ahead?: number;
    behind?: number;
    canApply: boolean;
  };
  type Preview = { inventory: Inventory; package?: PackageTarget; detail?: string; token: string; expires: string };
  type Section = { inventory: Inventory; preview?: Preview; checkedAt?: string; error?: string };
  type Status = {
    host: string;
    sections: Record<SectionName, Section>;
    busy: string;
    intervalMinutes: number;
    terminal: boolean;
    last: { message: string; failed: boolean; at: string } | null;
  };

  let status = $state<Status>();
  let error = $state('');
  let sending = $state(false);
  let now = $state(Date.now());
  let selected = $state<{ section: SectionName; token: string; packageName?: string }>();
  let dialog: HTMLDialogElement;
  let terminalToken = $state<string>();
  let consolePanel = $state<HTMLElement>();
  let reading = false;

  const sections = [
    { id: 'dotfiles', title: 'Dotfiles', description: 'Chezmoi source and local files' },
    { id: 'brew', title: 'Homebrew', description: 'Installed formulae and casks' },
  ] as const;

  const jobLabels: Record<string, string> = {
    check: 'Checking for updates…',
    shell: 'Terminal connected',
    'preview dotfiles': 'Preparing the dotfiles preview…',
    'preview brew': 'Preparing the Homebrew preview…',
    'apply dotfiles': 'Applying dotfiles…',
    'apply brew': 'Upgrading Homebrew packages…',
  };

  const changeLabels: Record<string, string> = {
    M: 'Modified', MM: 'Conflict', A: 'Added', D: 'Deleted', R: 'Script', T: 'Type changed',
  };

  async function refresh() {
    if (reading) return;
    reading = true;
    now = Date.now();
    try {
      const response = await fetch('/api/status');
      if (!response.ok) throw new Error('Could not read this host’s status.');
      status = await response.json();
      error = '';
    } catch (err) {
      error = err instanceof Error ? err.message : 'The dashboard is unreachable.';
    } finally {
      reading = false;
    }
  }

  async function run(operation: string, section?: SectionName, options?: { token?: string; package?: PackageTarget }) {
    sending = true;
    error = '';
    try {
      const response = await fetch('/api/' + operation, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Update-Request': '1' },
        body: JSON.stringify({ section, ...options }),
      });
      if (!response.ok) throw new Error((await response.text()).trim());
      await refresh();
    } catch (err) {
      error = err instanceof Error ? err.message : 'The request failed.';
    } finally {
      sending = false;
    }
  }

  function confirm(section: SectionName, preview: Preview) {
    selected = { section, token: preview.token, packageName: preview.package?.name };
    dialog.showModal();
  }

  async function apply() {
    if (!selected) return;
    dialog.close();
    if (selected.packageName && status?.terminal) {
      terminalToken = selected.token;
      await tick();
      consolePanel?.scrollIntoView({ block: 'nearest' });
      return;
    }
    void run('apply', selected.section, { token: selected.token });
  }

  function time(value: string) {
    return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value));
  }

  onMount(() => {
    void refresh();
    const timer = window.setInterval(refresh, 2500);
    return () => window.clearInterval(timer);
  });
</script>

<main class="page">
  <header class="page-header">
    <div>
      <p class="host">{status?.host ?? 'This machine'}</p>
      <h1>Host updates</h1>
      {#if status}<p class="subtitle">Checks every {status.intervalMinutes} min</p>{/if}
    </div>
    <div class="terminal-actions">
      {#if status?.terminal}<a class="quiet-link" href="/terminal">Terminal</a>{/if}
      <button class="primary" onclick={() => run('check')} disabled={sending || !!status?.busy}>
        Check now
      </button>
    </div>
  </header>

  {#if error}
    <p class="notice error" role="alert">{error}</p>
  {:else if status?.busy}
    <p class="notice activity" role="status">{jobLabels[status.busy]}</p>
  {:else if status?.last}
    <p class:error={status.last.failed} class="notice activity" role="status">
      <span>{status.last.message}</span><span class="muted">{time(status.last.at)}</span>
    </p>
  {/if}

  {#if terminalToken}
    <div class="update-terminal" bind:this={consolePanel}>
      {#key terminalToken}
        <Terminal mode="brew" preview={terminalToken} onclose={() => { terminalToken = undefined; }} />
      {/key}
    </div>
  {/if}

  <div class="sections">
    {#each sections as item}
      {@const section = status?.sections[item.id]}
      {@const preview = section?.preview}
      {@const packagePreview = preview?.package ? preview : undefined}
      {@const inventory = packagePreview ? section?.inventory : (preview?.inventory ?? section?.inventory)}
      {@const changes = inventory?.changes ?? []}
      {@const expired = !!preview?.token && Date.parse(preview.expires) <= now}
      {@const stale = !!section?.checkedAt && !!status && now - Date.parse(section.checkedAt) > status.intervalMinutes * 120_000}
      <section class="panel" aria-labelledby={'heading-' + item.id}>
        <div class="panel-title">
          <div>
            <h2 id={'heading-' + item.id}>{item.title}</h2>
            <p>{item.description}</p>
          </div>
          {#if section?.checkedAt}
            <span class="count" class:pending={changes.length > 0 || !!inventory?.behind}>
              {item.id === 'dotfiles' ? changes.length + (changes.length === 1 ? ' file' : ' files') : changes.length + ' outdated'}
            </span>
          {/if}
        </div>

        {#if section?.checkedAt}
          <p class="checked">Checked {time(section.checkedAt)}{stale ? ' · Stale' : ''}</p>
        {/if}
        {#if section?.error}
          <p class="notice error">{section.error}{section.checkedAt ? ' Showing the last successful check.' : ''}</p>
        {/if}

        {#if inventory && item.id === 'dotfiles' && inventory.revision}
          <dl class="revision">
            <div><dt>Checkout</dt><dd>{inventory.revision.slice(0, 8)}</dd></div>
            <div><dt>Upstream</dt><dd>{inventory.upstream?.slice(0, 8)}</dd></div>
            <div><dt>Incoming commits</dt><dd>{inventory.behind ?? 0}</dd></div>
          </dl>
          {#if inventory.ahead}
            <p class="notice error">{inventory.ahead} local commits. Reconcile the source checkout before applying.</p>
          {/if}
        {/if}

        {#if packagePreview}
          {@const packageChange = packagePreview.inventory.changes?.[0]}
          <div class="package-preview" aria-label="Package update preview">
            <h3>Update {packagePreview.package?.name}</h3>
            <p>{packageChange?.kind} · {packageChange?.current} → {packageChange?.available}</p>
            {#if packagePreview.detail}
              <details><summary>Homebrew dry run</summary><pre>{packagePreview.detail}</pre></details>
            {/if}
            {#if expired}
              <p class="muted">Preview expired. Select Update again.</p>
            {:else if packagePreview.token}
              <button class="primary" onclick={() => confirm('brew', packagePreview)} disabled={sending || !!status?.busy}>Review and confirm</button>
            {/if}
          </div>
        {/if}

        <div class="list-heading">
          {#if preview && !packagePreview}
            <h3>Update preview</h3>
          {:else}
            <h3>{item.id === 'dotfiles' ? 'Changes in current checkout' : 'Available upgrades'}</h3>
          {/if}
        </div>
        {#if changes.length}
          <!-- svelte-ignore a11y_no_noninteractive_tabindex (Keyboard users need to focus the scrolling table.) -->
          <div class="changes" role="region" aria-label={item.title + ' changes'} tabindex="0">
            <table>
              <thead><tr><th scope="col">{item.id === 'dotfiles' ? 'File' : 'Package'}</th><th scope="col">{item.id === 'dotfiles' ? 'Change' : 'Available version'}</th>{#if item.id === 'brew'}<th scope="col"><span class="visually-hidden">Action</span></th>{/if}</tr></thead>
              <tbody>
                {#each changes as change}
                  <tr>
                    <td>
                      <span class="item-name">{change.name}</span>
                      {#if item.id === 'brew'}<small>{change.kind} · Installed <span class="version">{change.current}</span>{change.pinned ? ' · Pinned' : ''}</small>{/if}
                    </td>
                    <td class:version={item.id === 'brew'}>{item.id === 'brew' ? change.available : (changeLabels[change.kind ?? ''] ?? change.kind)}</td>
                    {#if item.id === 'brew'}
                      <td class="update-cell">
                        {#if !change.pinned && change.kind}
                          {@const target = { name: change.name, kind: change.kind }}
                          <button
                            aria-label={'Update ' + change.name + ' (' + change.kind + ')'}
                            onclick={() => run('preview', 'brew', { package: target })}
                            disabled={sending || !!status?.busy}
                          >Update</button>
                        {/if}
                      </td>
                    {/if}
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        {:else}
          <p class="empty">{section?.checkedAt || preview ? 'No changes to show' : 'Waiting for the first successful check'}</p>
        {/if}

        {#if preview?.detail && !packagePreview}
          {#if item.id === 'brew'}
            <details><summary>Homebrew dry run</summary><pre>{preview.detail}</pre></details>
          {:else}
            <p class="notice error">{preview.detail}</p>
          {/if}
        {/if}

        <footer class="panel-actions">
          <button onclick={() => run('preview', item.id)} disabled={sending || !!status?.busy || !section?.checkedAt}>
            {item.id === 'brew' ? 'Preview all upgrades' : (preview ? 'Refresh preview' : 'Preview changes')}
          </button>
          {#if preview?.token && !expired && !packagePreview}
            <button class="primary" onclick={() => confirm(item.id, preview)} disabled={sending || !!status?.busy}>
              {item.id === 'dotfiles' ? 'Apply files' : 'Upgrade all packages'}
            </button>
          {:else if expired && !packagePreview}
            <span class="muted">Preview expired</span>
          {/if}
        </footer>
      </section>
    {/each}
  </div>
</main>

<dialog bind:this={dialog} aria-labelledby="confirm-title">
  <h2 id="confirm-title">{selected?.packageName ? 'Upgrade ' + selected.packageName + '?' : (selected?.section === 'brew' ? 'Upgrade all packages?' : 'Apply dotfile changes?')}</h2>
  <p>The dashboard will check the preview again before making changes on this host.</p>
  <div class="dialog-actions">
    <button onclick={() => dialog.close()}>Cancel</button>
    <button class="primary" onclick={apply}>Confirm update</button>
  </div>
</dialog>
