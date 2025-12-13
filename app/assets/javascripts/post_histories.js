document.addEventListener('DOMContentLoaded', () => {
  const openRelevantEditOnly = () => {
    document.querySelectorAll('details.history-event').forEach((el) => {
      if (el instanceof HTMLDetailsElement) {
        el.open = false;
      }
    });

    const [hash] = location.hash.split(':~:');
    const historyId = hash.slice(1);

    const historyItem = document.getElementById(historyId);

    if (historyItem instanceof HTMLDetailsElement) {
      historyItem.open = true;
    }
  };

  window.addEventListener('hashchange', openRelevantEditOnly);
  openRelevantEditOnly();
});
