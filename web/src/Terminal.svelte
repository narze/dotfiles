<script lang="ts">
  import { onMount } from 'svelte';
  import { Terminal } from '@xterm/xterm';
  import { FitAddon } from '@xterm/addon-fit';
  import '@xterm/xterm/css/xterm.css';
  import './fonts/terminal-font.css';

  let { mode, preview, onclose }: { mode: 'shell' | 'brew'; preview?: string; onclose?: () => void } = $props();
  let pane: HTMLDivElement;
  let connection: WebSocket | undefined;
  let request: AbortController | undefined;
  let term: Terminal;
  let fit: FitAddon;
  let phase = $state<'idle' | 'connecting' | 'open' | 'finished'>('idle');
  let message = $state('');
  let initialized = $state(false);

  function send(payload: object) {
    if (connection?.readyState === WebSocket.OPEN) connection.send(JSON.stringify(payload));
  }

  async function connect() {
    phase = 'connecting';
    message = 'Connecting…';
    term.clear();
    request = new AbortController();
    try {
      const response = await fetch('/api/terminal-ticket', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Update-Request': '1' },
        body: JSON.stringify({ mode, preview }),
        signal: request.signal,
      });
      if (!response.ok) throw new Error((await response.text()).trim());
      const { ticket } = await response.json();
      if (request.signal.aborted) return;

      const url = new URL('/api/terminal', window.location.href);
      url.protocol = 'wss:';
      const socket = new WebSocket(url);
      socket.binaryType = 'arraybuffer';
      connection = socket;
      socket.onopen = () => {
        fit.fit();
        send({ type: 'open', ticket, cols: term.cols, rows: term.rows });
      };
      socket.onmessage = ({ data }) => {
        if (data instanceof ArrayBuffer) {
          term.write(new Uint8Array(data));
          return;
        }
        const event = JSON.parse(data);
        message = event.data;
        if (event.type === 'ready') {
          phase = 'open';
          term.focus();
        }
        if (event.type === 'done' || event.type === 'error') {
          phase = 'finished';
          term.writeln('\r\n' + event.data);
        }
      };
      socket.onclose = () => {
        if (phase !== 'finished') {
          phase = 'finished';
          message = mode === 'brew'
            ? 'Disconnected. A running update continues on the Mac.'
            : 'Shell disconnected.';
        }
      };
    } catch (error) {
      if (request.signal.aborted) return;
      phase = 'finished';
      message = error instanceof Error ? error.message : 'Terminal connection failed.';
    }
  }

  function disconnect() {
    request?.abort();
    connection?.close();
    phase = 'finished';
    message = mode === 'shell' ? 'Shell disconnected.' : 'Console closed.';
    onclose?.();
  }

  function mountTerminal() {
    term = new Terminal({
      cursorBlink: true,
      fontFamily: '"Fantasque Nerd Mono", ui-monospace, Menlo, monospace',
      fontSize: 13,
      scrollback: 3000,
      theme: { background: '#17221d', foreground: '#ebf3ee', cursor: '#a6d3bb' },
      linkHandler: { activate: () => {} },
    });
    fit = new FitAddon();
    term.loadAddon(fit);
    term.open(pane);
    const resize = new ResizeObserver(() => fit.fit());
    resize.observe(pane);
    const input = term.onData(data => {
      if (phase !== 'open') return;
      for (const chunk of data.match(/.{1,4096}/gsu) ?? []) send({ type: 'input', data: chunk });
    });
    const dimensions = term.onResize(({ cols, rows }) => send({ type: 'resize', cols, rows }));
    initialized = true;
    if (mode === 'brew') void connect();
    return () => {
      request?.abort();
      connection?.close();
      resize.disconnect();
      input.dispose();
      dimensions.dispose();
      term.dispose();
    };
  }

  onMount(() => {
    let disposed = false;
    let unmount: (() => void) | undefined;
    // xterm measures character cells when it opens. Load both faces first.
    void Promise.allSettled([
      document.fonts.load('400 13px "Fantasque Nerd Mono"'),
      document.fonts.load('700 13px "Fantasque Nerd Mono"'),
    ]).then(() => {
      if (!disposed) unmount = mountTerminal();
    });
    return () => {
      disposed = true;
      unmount?.();
    };
  });
</script>

<section class="terminal-panel" aria-label={mode === 'brew' ? 'Homebrew terminal' : 'Interactive shell'}>
  <header class="terminal-header">
    <div>
      <h2>{mode === 'brew' ? 'Homebrew terminal' : 'Interactive shell'}</h2>
      <p role="status">{message || 'Open a shell as the dashboard’s Mac user.'}</p>
    </div>
    <div class="terminal-actions">
      {#if mode === 'shell' && (phase === 'idle' || phase === 'finished')}
        <button class="primary" onclick={connect} disabled={!initialized}>Connect</button>
      {:else}
        <button onclick={() => send({ type: 'input', data: '\u0003' })} disabled={phase !== 'open'}>Ctrl+C</button>
        <button onclick={disconnect}>{mode === 'brew' ? 'Close console' : 'Disconnect'}</button>
      {/if}
    </div>
  </header>
  <div class="terminal-screen" bind:this={pane}></div>
</section>
