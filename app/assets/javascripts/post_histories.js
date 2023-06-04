$(() => {
  const openRelevantEditOnly = () => {
    $("details.history-event").attr('open', false);
    $(location.hash).attr('open', true);
  }

  window.addEventListener("hashchange", openRelevantEditOnly);
  openRelevantEditOnly();
});
