pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string sourceFile: "/usr/share/unicode/emoji/emoji-test.txt"

  property var all: []

  function search(text: string): var {
    if (text === "")
      return all;
    return all
      .map((emoji, order) => ({
        emoji: emoji,
        order: order,
        score: TextSearch.score(text, emoji.title, [emoji.subtitle]),
      }))
      .filter(result => result.score > 0)
      .sort((a, b) => b.score - a.score || a.order - b.order)
      .map(result => result.emoji);
  }

  function parse(content: string): var {
    const emojis = [];
    let group = "";

    for (const line of content.split("\n")) {
      if (line.startsWith("# group: ")) {
        group = line.slice("# group: ".length);
        continue;
      }

      const match = line.match(/; fully-qualified\s+# (\S+) E\d+\.\d+ (.+)$/);
      if (!match)
        continue;

      const [, glyph, name] = match;
      if (name.includes("skin tone"))
        continue;

      emojis.push({
        kind: "emoji",
        title: name,
        subtitle: group,
        icon: "",
        glyph: glyph,
        text: glyph,
      });
    }
    return emojis;
  }

  FileView {
    path: root.sourceFile
    onLoaded: root.all = root.parse(text())
    onLoadFailed: console.warn(`Emojis: can't read ${root.sourceFile}. Is the unicode-emoji package installed?`)
  }
}
