/*! Code Golf Leaderboard script
 *  Author: Moshi <https://github.com/MoshiKoi>
 *  License: AGPLv3
 */

(() => {
  const dom_parser = new DOMParser();
  const match = location.pathname.match(/(?<=posts\/)\d+/);

  // Don't run on non-post pages.
  if (!match) {
    return;
  }

  const CHALLENGE_ID = match[0];
  let leaderboard;
  let sort;

  console.log(`CG Leaderboard active, challenge ID ${CHALLENGE_ID}`);

  /**
   * Wrapper around localStorage
   */
  const settings = {
    _defaults: {
      groupByLanguage: true,
      showPlacements: true
    },
    currentSettings: {}, // Used as a fallback if localStorage is unavailable
    get groupByLanguage() {
      return this._get('groupByLanguage');
    },
    set groupByLanguage(value) {
      return this._set('groupByLanguage', value);
    },

    get showPlacements() {
      return this._get('showPlacements');
    },
    set showPlacements(value) {
      return this._set('showPlacements', value);
    },

    _get(name) {
      try {
        return this.currentSettings[name] ?? JSON.parse(localStorage.getItem(name)) ?? this._defaults[name];
      } catch (err) {
        // console.warn(`Failed to retrieve ${name} from localStorage`);
        return this._defaults[name];
      }
    },
    _set(name, value) {
      try {
        this.currentSettings[name] = value
        localStorage.setItem(name, JSON.stringify(value));
      } catch (err) {
        // console.warn(`Failed to store ${name} into localStorage`);
      }
    }
  };

  async function getLeaderboard(id) {
    const response = await fetch(`/posts/${id}`);
    const text = await response.text();

    const doc = dom_parser.parseFromString(text.toString(), 'text/html');

    const pagination = doc.querySelector('.pagination');
    const num_pages = pagination ? parseInt(pagination.querySelector('.next').previousElementSibling.innerText) : 1;

    const pagePromises = [];
    for (let i = 1; i <= num_pages; i++) {
      pagePromises.push(fetch(`/posts/${id}?sort=active&page=${i}`).then(response => response.text()));
    }

    const leaderboard = [];

    for (let i = 0; i < pagePromises.length; i++) {
      const text = await pagePromises[i];
      const doc = dom_parser.parseFromString(text.toString(), 'text/html');
      const [question, ...page_answers] = doc.querySelectorAll('.post');
      const non_deleted_answers = page_answers.filter(answer => answer.querySelector('.deleted-content') === null);

      for (const answerPost of non_deleted_answers) {

        const header = answerPost.querySelector('h1, h2, h3');
        const code = header.parentElement.querySelector(':scope > pre > code');
        const full_language = header ? header.innerText.split(',')[0].trim() : undefined
        const regexGroups = full_language?.match(/(?<language>.+?)(?: \((?<variant>.+)\))?(?: \+ (?<extensions>.+))?$/)?.groups ?? {};
        const { language, variant, extensions } = regexGroups;

        const entry = {
          answerID: answerPost.id,
          answerURL: answerPost.querySelector('.js-permalink').href,
          page: i + 1, // +1 because pages are 1-indexed while arrays are 0-indexed
          username: answerPost.querySelector('.user-card--link').firstChild.data.trim(),
          userid: answerPost.querySelector('.user-card--link').href.match(/\d+/)[0],
          full_language, full_language,
          language: language,
          variant: variant,
          extensions: extensions,
          code: code?.innerText,
          score: header ? header.innerText.match(/\d+/g)?.pop() : undefined
        };

        leaderboard.push(entry);
      }
    }

    return leaderboard;
  }

  function augmentLeaderboardWithPlacements(leaderboard, comparator) {
    leaderboard.sort(comparator);

    let placement = 1;
    let slack = 0;

    leaderboard[0].placement = 1;

    for (let i = 1; i < leaderboard.length; i++) {
      slack++;

      // If they compare equal (returns 0), we don't increase the placement
      if (comparator(leaderboard[i], leaderboard[i - 1])) {
        placement += slack;
        slack = 0;
      }

      leaderboard[i].placement = placement;
    }
  }

  const embed = document.createElement('div');
  embed.innerHTML = `
<div class="toc cg-leaderboard">
  <div class="cgl-container">
    <button class="toc--header has-margin-2" id="leaderboards-header">Leaderboards by language</button>
    <div class="has-padding-2 cgl-option">
      <label>
        Group by language
        <input id="group-by-lang" type="checkbox" ${settings.groupByLanguage ? 'checked' : ''}>
      </label>
    </div>
    <div class="has-padding-2">
      <label>
        Show placements
        <input id="show-placement" type="checkbox" ${settings.showPlacements ? 'checked' : ''}>
      </label>
    </div>
  </div>

  <div id="toc-rows"></div>
</div>`;

  const leaderboardsTable = embed.querySelector('#toc-rows');
  const toggle = embed.querySelector('#leaderboards-header');
  toggle.addEventListener('click', _ => { 
    if (leaderboardsTable.style.display === 'none') {
      refreshBoard();
      leaderboardsTable.style.display = 'block';
    } else {
      leaderboardsTable.style.display = 'none';
    }
  });
  const groupByLanguageInput = embed.querySelector('#group-by-lang');
  const showPlacementsInput = embed.querySelector('#show-placement');

  groupByLanguageInput.addEventListener('click', _ => {
    settings.groupByLanguage = groupByLanguageInput.checked;
    refreshBoard();
  });
  showPlacementsInput.addEventListener('click', _ => {
    settings.showPlacements = showPlacementsInput.checked;
    refreshBoard();
  });

  function refreshBoard() {
    // Clear table
    leaderboardsTable.querySelectorAll('a').forEach(el => el.remove());

    if (settings.groupByLanguage) {
      renderLeaderboardsByLanguage();
    } else {
      renderLeaderboardsByByteCount();
    }
  }

  /**
   * Helper function
   * Turns arrays into associative arrays
   */
  function createGroups(array, categorizer) {
    const groups = {};

    for (const item of array) {
      const category = categorizer(item);
      if (groups[category]) {
        groups[category].push(item);
      } else {
        groups[category] = [item];
      }
    }

    return groups;
  }

  function createRow(answer) {
    const row = document.createElement('a');
    row.classList.add('toc--entry');
    row.href = answer.answerURL;

    row.innerHTML = `
    <div class="toc--badge"><span class="badge is-tag is-green">${answer.score}</span></div>
    <div class="toc--full"><p class="row-summary"><span class='username'></span></p></div>
    ${answer.placement === 1 ? '<div class="toc--badge"><span class="badge is-tag is-yellow"><i class="fas fa-trophy"></i></span></div>'
      : (settings.showPlacements ? `<div class="toc--badge"><span class="badge is-tag">#${answer.placement}</span></div>` : '')}
    <div class="toc--badge"><span class="language-badge badge is-tag is-blue"></span></div>`;

    row.querySelector('.username').innerText = answer.username
    row.querySelector('.language-badge').innerText = answer.full_language;
    if (answer.code) {
      row.querySelector('.username').after(document.createElement('code'));
      row.querySelector('code').innerText = answer.code.split('\n')[0].substring(0, 200);
    } else {
      row.querySelector('.username').insertAdjacentHTML('afterend', '<em>Invalid entry format</em>');
    }

    return row;
  }

  async function renderLeaderboardsByLanguage() {
    leaderboard = leaderboard || await getLeaderboard(CHALLENGE_ID);
    const languageLeaderboards = createGroups(leaderboard, entry => entry.full_language);

    for (const language in languageLeaderboards) {
      augmentLeaderboardWithPlacements(languageLeaderboards[language], sort);

      for (const answer of languageLeaderboards[language]) {
        const row = createRow(answer);
        leaderboardsTable.appendChild(row);
      }
    }
  }

  async function renderLeaderboardsByByteCount() {
    leaderboard = leaderboard || await getLeaderboard(CHALLENGE_ID);
    augmentLeaderboardWithPlacements(leaderboard, sort);

    for (const answer of leaderboard) {
      const row = createRow(answer);
      leaderboardsTable.appendChild(row);
    }
  }

  window.addEventListener('DOMContentLoaded', _ => {
    if (document.querySelector('.category-header--name').innerText.trim() === 'Challenges') {
      const question_tags = [...document.querySelector('.post--tags').children].map(el => el.innerText);
      
      if (question_tags.includes('code-golf') || question_tags.includes('lowest-score')) {
        sort = (x, y) => x.score - y.score;
        document.querySelector('.post:first-child').nextElementSibling.insertAdjacentElement('afterend', embed);
        refreshBoard();
      } else if (question_tags.includes('code-bowling') || question_tags.includes('highest-score')) {
        sort = (x, y) => y.score - x.score;
        document.querySelector('.post:first-child').nextElementSibling.insertAdjacentElement('afterend', embed);
        refreshBoard();
      }
    }
  });
})();
