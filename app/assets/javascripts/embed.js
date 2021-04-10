$(() => {
  $('.post--content a').each((i, e) => {
    const $tgt = $(e);
    const href = $tgt.attr('href');

    if (!href) {
      return;
    }

    // Only embed raw YT links, i.e. not [text](link), only [link](link)
    if ((href.startsWith('https://youtube.com') || href.startsWith('https://www.youtube.com')) && $tgt.text() === href) {
      const videoId = /v=([^$&]+)/.exec(href);
      $tgt.after(`<iframe width="100%" height="380" src="https://www.youtube-nocookie.com/embed/${videoId[1]}" frameborder="0" allowfullscreen
                          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"></iframe>`);
      $tgt.remove();
    }

    // Likewise, only raw Spotify links
    if (href.startsWith('https://open.spotify.com') && $tgt.text() === href) {
      const uri = href.replace('open.spotify.com', 'open.spotify.com/embed');
      $tgt.after(`<iframe src="${uri}" width="300" height="80" frameborder="0" allowtransparency="true"
                          allow="encrypted-media"></iframe>`);
      $tgt.remove();
    }
  });
});