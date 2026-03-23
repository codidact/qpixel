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
 *   placement?: number
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

  /**
   * @type {ChallengeEntry[] | undefined}
   */
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
      this._set('groupByLanguage', value);
    },
    get showPlacements() {
      return this._get('showPlacements');
    },
    set showPlacements(value) {
      this._set('showPlacements', value);
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
    const num_pages = pagination ? parseInt(pagination.querySelector('.next').previousElementSibling.textContent) : 1;

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
      const non_deleted_answers = page_answers.filter((answer) => answer.querySelector('.js-deleted-post') === null);

      for (const answerPost of non_deleted_answers) {
        /** @type {HTMLElement | null} */
        const header = answerPost.querySelector('h1, h2, h3');
        /** @type {HTMLElement | null} */
        const codeEl = header?.parentElement.querySelector(':scope > pre > code');
        const full_language = header?.innerText.split(',')[0].trim();
        const regexGroups = full_language?.match(/(?<language>.+?)(?: \((?<variant>.+)\))?(?: \+ (?<extensions>.+))?$/)?.groups ?? {};
        const { language, variant, extensions } = regexGroups;
        /** @type {HTMLAnchorElement | null} */
        const userlinkEl = answerPost.querySelector(".user-card--content .user-card--link");
        /** @type {HTMLAnchorElement | null} */
        const answerLinkEl = answerPost.querySelector('.js-permalink');

        // https://regex101.com/r/BjIjk5/2
        const matchedScore = header?.innerText.match(/\d+(?:\.\d+)?/g)?.pop();

        /** @type {ChallengeEntry} */
        const entry = {
          answerID: answerPost.id,
          answerURL: answerLinkEl?.href,
          page: i + 1, // +1 because pages are 1-indexed while arrays are 0-indexed
          username: userlinkEl?.firstChild?.textContent?.trim() || 'deleted user',
          userid: userlinkEl?.href?.match(/\d+/)?.[0] || '',
          full_language,
          language,
          variant,
          extensions,
          code: codeEl?.innerText,
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

  /** @type {HTMLElement | null} */
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

  /** @type {HTMLInputElement | null} */
  const groupByLanguageInput = embed.querySelector('#group-by-lang');
  /** @type {HTMLInputElement | null} */
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
    /** @type {Record<string, T[]>} */
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
    <div class="toc--badge"><span class="badge is-tag is-green">${answer.score ?? 'N/A'}</span></div>
    <div class="toc--full"><p class="row-summary"><span class='username has-padding-right-1'></span></p></div>
    ${answer.placement === 1 ? '<div class="toc--badge"><span class="badge is-tag is-yellow"><i class="fas fa-trophy"></i></span></div>'
      : (settings.showPlacements ? `<div class="toc--badge"><span class="badge is-tag">#${answer.placement}</span></div>` : '')}
    <div class="toc--badge"><span class="language-badge badge is-tag is-blue"></span></div>`;

    /** @type {HTMLElement | null} */
    const usernameEl = row.querySelector('.username');
    /** @type {HTMLElement | null} */
    const langBadgeEl = row.querySelector('.language-badge');

    usernameEl.innerText = answer.username;
    langBadgeEl.innerText = answer.full_language ?? 'N/A';

    if (answer.code) {
      usernameEl.after(document.createElement('code'));
      row.querySelector('code').innerText = answer.code.split('\n')[0].substring(0, 200);
    } else if (answer.code !== '') {
      usernameEl.insertAdjacentHTML('afterend', '<em>Invalid entry format</em>');
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
    /** @type {HTMLElement | null} */
    const categoryNameEl = document.querySelector(".category-header--name");

    const categoryName = categoryNameEl.innerText.trim();

    if (categoryName !== 'Challenges') {
      return;
    }

    /** @type {NodeListOf<HTMLElement>} */
    const questionTagsElements = document.querySelectorAll(".post--tags > a");

    const questionTags = [...questionTagsElements].map((el) => el.innerText);

    if (
      questionTags.includes("code-golf") ||
      questionTags.includes("lowest-score")
    ) {
      // If x were undefined, it would be automatically sorted to the end, but not so if x.score is undefined, so this needs to be stated explicitly.
      sort = (x, y) => typeof x.score === "undefined" ? 1 : x.score - y.score;

      document.querySelector(".js-answers-header")?.insertAdjacentElement('beforebegin', embed);

      refreshBoard(sort);
    } else if (
      questionTags.includes("code-bowling") ||
      questionTags.includes("highest-score")
    ) {
      // If x were undefined, it would be automatically sorted to the end, but not so if x.score is undefined, so this needs to be stated explicitly.
      sort = (x, y) => typeof x.score === "undefined" ? 1 : y.score - x.score;

      document.querySelector(".js-answers-header")?.insertAdjacentElement("beforebegin", embed);

      refreshBoard(sort);
    }
  });
})();
