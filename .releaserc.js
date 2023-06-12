module.exports = {
  branches: ["main", "master"],
  ci: false,
  tagFormat: "microservice-chart-${version}",
  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "angular",
        releaseRules: [
          { type: "breaking", release: "major" },
          { type: "major", release: "major" },
        ],
      },
    ],
    "@semantic-release/release-notes-generator",
    "@semantic-release/github",
  ],
};
