pragma Singleton

import Quickshell

Singleton {
  function score(text: string, name: string, extras: var): int {
    const query = text.toLowerCase();
    const target = name.toLowerCase();

    if (target === query)
      return 120;
    if (target.startsWith(query))
      return 100;
    if (target.split(/[\s\-_.:]+/).some(word => word.startsWith(query)))
      return 80;
    if (target.includes(query))
      return 60;
    if (extras.some(extra => extra && extra.toLowerCase().includes(query)))
      return 40;
    if (containsInOrder(target, query))
      return 20;
    return 0;
  }

  function containsInOrder(name: string, text: string): bool {
    let position = 0;
    for (const letter of text) {
      position = name.indexOf(letter, position);
      if (position === -1)
        return false;
      position++;
    }
    return true;
  }
}
