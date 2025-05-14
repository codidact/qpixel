/*! Code Golf Leaderboard script
 *  Author: Moshi <https://github.com/MoshiKoi>
 *  License: AGPLv3
 */

/**
 * @typedef {{
 *   answerID: string
 *   answerURL?: string
 *   page: number
 *   username: string
 *   userid: string
 *   full_language?: string
 *   language?: string
 *   variant?: string
 *   extensions?: string
 *   code?: string
 *   score?: number
 * }} ChallengeEntry
 * 
 * @typedef {(a: ChallengeEntry, b: ChallengeEntry) => number} SortComparator
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

  /**
   * @type {SortComparator | undefined}
   */
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

  /**
   * @param {string} id challenge id for which to get the leaderboard
   * @returns {Promise<ChallengeEntry[]>}
   */
  async function getLeaderboard(id) {
    const response = await fetch(`/posts/${id}`);
    const text = await response.text();

    const doc = dom_parser.parseFromString(text.toString(), 'text/html');

    const pagination = doc.querySelector('.pagination');
    const num_pages = pagination ? parseInt(pagination.querySelector('.next').previousElementSibling.innerText) : 1;

    const pagePromises = [];
    for (let i = 1; i <= num_pages; i++) {
      pagePromises.push(fetch(`/posts/${id}?sort=active&page=${i}`).then((response) => response.text()));
    }

    /** @type {ChallengeEntry[]} */
    const leaderboard = [];

    for (let i = 0; i < pagePromises.length; i++) {
      const text = await pagePromises[i];
      const doc = dom_parser.parseFromString(text.toString(), 'text/html');
      const [question, ...page_answers] = doc.querySelectorAll('.post');
      const non_deleted_answers = page_answers.filter((answer) => answer.querySelector('.deleted-content') === null);

      for (const answerPost of non_deleted_answers) {

        /** @type {HTMLElement | null} */
        const header = answerPost.querySelector('h1, h2, h3');
        const code = header?.parentElement.querySelector(':scope > pre > code');
        const full_language = header?.innerText.split(',')[0].trim();
        const regexGroups = full_language?.match(/(?<language>.+?)(?: \((?<variant>.+)\))?(?: \+ (?<extensions>.+))?$/)?.groups ?? {};
        const { language, variant, extensions } = regexGroups;
        const userlink = answerPost.querySelector(
          ".user-card--content .user-card--link",
        );

        const matchedScore = header?.innerText.match(/\d+/g)?.pop();

        /** @type {ChallengeEntry} */
        const entry = {
          answerID: answerPost.id,
          answerURL: answerPost.querySelector('.js-permalink').href,
          page: i + 1, // +1 because pages are 1-indexed while arrays are 0-indexed
          username: userlink.firstChild.data.trim(),
          userid: userlink.href.match(/\d+/)[0],
          full_language,
          language,
          variant,
          extensions,
          code: code?.innerText,
          score: isFinite(+matchedScore) ? +matchedScore : void 0
        };

        leaderboard.push(entry);
      }
    }

    return leaderboard;
  }

  /**
   * @param {ChallengeEntry[]} leaderboard list of challenge entries to augment
   * @param {SortComparator} comparator compare function for sorting
   * @returns {void}
   */
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
  toggle.addEventListener('click', (_) => { 
    if (leaderboardsTable.style.display === 'none') {
      refreshBoard(sort);
      leaderboardsTable.style.display = 'block';
    } else {
      leaderboardsTable.style.display = 'none';
    }
  });
  const groupByLanguageInput = embed.querySelector('#group-by-lang');
  const showPlacementsInput = embed.querySelector('#show-placement');

  groupByLanguageInput.addEventListener('click', (_) => {
    settings.groupByLanguage = groupByLanguageInput.checked;
    refreshBoard(sort);
  });

  showPlacementsInput.addEventListener('click', (_) => {
    settings.showPlacements = showPlacementsInput.checked;
    refreshBoard(sort);
  });

  /**
   * @param {SortComparator} comparator
   */
  function refreshBoard(comparator) {
    // Clear table
    leaderboardsTable.querySelectorAll('a').forEach((el) => el.remove());

    if (settings.groupByLanguage) {
      renderLeaderboardsByLanguage(comparator);
    } else {
      renderLeaderboardsByByteCount(comparator);
    }
  }

  /**
   * Turns arrays into associative arrays
   * @template {unknown} T
   * @param {T[]} array array to group
   * @param {(item: T) => string} categorizer
   * @returns {Record<string, T[]>}
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

  /**
   * @param {ChallengeEntry} answer challenge entry to create row for
   * @returns {HTMLAnchorElement}
   */
  function createRow(answer) {
    const row = document.createElement('a');
    row.classList.add('toc--entry');
    row.href = answer.answerURL;

    row.innerHTML = `
    <div class="toc--badge"><span class="badge is-tag is-green">${answer.score}</span></div>
    <div class="toc--full"><p class="row-summary"><span class='username has-padding-right-1'></span></p></div>
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

  /**
   * @param {SortComparator} comparator
   */
  async function renderLeaderboardsByLanguage(comparator) {
    leaderboard = leaderboard || await getLeaderboard(CHALLENGE_ID);
    const languageLeaderboards = createGroups(leaderboard, (entry) => entry.full_language);

    // sorted using default alphanumeric sort
    const sortedLanguageKeys = Object.keys(languageLeaderboards).sort()

    for (const language of sortedLanguageKeys) {
      augmentLeaderboardWithPlacements(languageLeaderboards[language], comparator);

      for (const answer of languageLeaderboards[language]) {
        const row = createRow(answer);
        leaderboardsTable.appendChild(row);
      }
    }
  }

  /**
   * @param {SortComparator} comparator
   */
  async function renderLeaderboardsByByteCount(comparator) {
    leaderboard = leaderboard || await getLeaderboard(CHALLENGE_ID);
    augmentLeaderboardWithPlacements(leaderboard, comparator);

    for (const answer of leaderboard) {
      const row = createRow(answer);
      leaderboardsTable.appendChild(row);
    }
  }

  window.addEventListener("DOMContentLoaded", (_) => {
    if (
      document.querySelector(".category-header--name").innerText.trim() ===
      "Challenges"
    ) {
      const question_tags = [
        ...document.querySelector(".post--tags").children,
      ].map((el) => el.innerText);

      if (
        question_tags.includes("code-golf") ||
        question_tags.includes("lowest-score")
      ) {
        // If x were undefined, it would be automatically sorted to the end, but not so if x.score is undefined, so this needs to be stated explicitly.
        sort = (x, y) => typeof x.score === "undefined" ? 1 : x.score - y.score;

        document
          .querySelector(".post:first-child")
          .nextElementSibling.insertAdjacentElement("afterend", embed);

        refreshBoard(sort);
      } else if (
        question_tags.includes("code-bowling") ||
        question_tags.includes("highest-score")
      ) {
        // If x were undefined, it would be automatically sorted to the end, but not so if x.score is undefined, so this needs to be stated explicitly.
        sort = (x, y) => typeof x.score === "undefined" ? 1 : y.score - x.score;

        document
          .querySelector(".post:first-child")
          .nextElementSibling.insertAdjacentElement("afterend", embed);

        refreshBoard(sort);
      }
    }
  });
})();
