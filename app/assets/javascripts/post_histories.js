$(() => {
  const openRelevantEditOnly = () => {
    $("details.history-event").prop('open', false);
    $(location.hash).prop('open', true);
  }

  window.addEventListener("hashchange", openRelevantEditOnly);
  openRelevantEditOnly();
});
