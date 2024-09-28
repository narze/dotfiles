export function modifyConfig(config: Config): Config {
  config.slashCommands?.push({
    name: "review",
    description: "Review code changes from diff",
    run: async function* (sdk) {
      const diff = await sdk.ide.getDiff();
      const prompt = [
        diff,
        "The code above is the git diff before commit. Please read only the added/deleted changes and check for any mistakes. You should look for the following, and be extremely vigilant:",
        "- Syntax errors",
        "- Logic errors",
        "- Security vulnerabilities",
        "- Performance issues",
        "- Anything else that looks wrong",
        "Once you find an error, please explain it as clearly as possible, but without using extra words. For example, instead of saying 'I think there is a syntax error on line 5', you should say 'Syntax error on line 5'. Give your answer as one bullet point per mistake found.",
        "Also add code changes in markdown format if applicable.",
      ].join("\n");

      for await (const message of sdk.llm.streamComplete(prompt, {
        maxTokens: 2048,
      })) {
        yield message;
      }
    },
  });
  return config;
}
