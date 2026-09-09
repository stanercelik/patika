// Artboard'ları ortak CSS + gövde parçasından üretir. Design Components
// dosyaları birbiriyle hiçbir şey paylaşmadığı için stil her dosyaya gömülüyor;
// tek kaynak burada duruyor ki dokuz artboard birbirinden ayrışmasın.
import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const css = readFileSync(join(here, "_shared.css"), "utf8");

for (const file of readdirSync(join(here, "parts"))) {
  if (!file.endsWith(".html")) continue;
  const name = file.replace(/\.html$/, "");
  const body = readFileSync(join(here, "parts", file), "utf8");
  const out = `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <style>
${css}
  </style>
</helmet>
${body.trim()}
</x-dc>
</body>
</html>
`;
  writeFileSync(join(here, `${name}.dc.html`), out);
  console.log(`wrote ${name}.dc.html`);
}
