interface ElementOffset {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

interface PostValidatorMessage {
  type: "error" | "warning" | "error";
  message: string;
}

type PostValidator = (postText: string) => [boolean, PostValidatorMessage[]];

interface UserPreferences {
  community: Record<string, string | null>;
  global: Record<string, string | null>;
}

interface DelegatedListener {
  event: string;
  selector: string;
  callback: (ev: Event) => void;
}

type EventCallback = (event: Event) => void;

interface QPixelDOM {
  // private properties
  _delegatedListeners?: DelegatedListener[];
  _eventListeners?: Record<string, (ev: Event) => void>;

  // public methods
  addDelegatedListener?: (event: string, selector: string, callback: EventCallback) => void;
  addSelectorListener?: (event: string, selector: string, callback: EventCallback) => void;
  fadeOut?: (element: HTMLElement, duration: number) => void;
  setVisible?: (elements: HTMLElement | HTMLElement[], visible: boolean) => void;
}

type QPixelKeyboardState =
  | "home"
  | "goto"
  | "tools"
  | "goto/category-tags"
  | "goto/category-edits"
  | "goto/category"
  | "tools/vote";

type SelectedItemType = "link" | "post";

// TODO: rename CodidactKeyboard
interface QPixelKeyboard {
  is_mod: boolean;
  state: QPixelKeyboardState;
  selectedItem: HTMLElement | null;
  selectedItemData?: {
    type: SelectedItemType;
    post_id: string;
  };
  user_id: number | null;

  categories: () => Record<string, string>;
  dialog: (message: string) => void;
  dialogClose: () => void;
  updateSelected: () => void;
}

type NotificationType = "warning" | "success" | "danger";

type QPixelPopupCallback = (ev: JQuery.ClickEvent, popup: QPixelPopup) => void

type QPixelPingablePopupCallback = (ev: JQuery.KeyUpEvent)=> Promise<void>

declare class QPixelPopup {
  static destroyAll: () => void;
  static getPopup: (
    items: JQuery[],
    field: HTMLInputElement | HTMLTextAreaElement,
    callback: QPixelPopupCallback
  ) => QPixelPopup;
  static isSpecialKey: (keyCode: number) => boolean;

  constructor(
    items: JQuery[], 
    field: HTMLInputElement | HTMLTextAreaElement, 
    callback: QPixelPopupCallback
  );

  destroy: () => void;
  getActiveIdx: () => number | null;
  setActive: (index: number) => void;
  setCallback: (callback: QPixelPopupCallback) => void;
  getClickHandler: () => (ev: JQuery.Event) => void;
  getKeyHandler: () => (ev: JQuery.KeyboardEventBase) => void;
  updateItems: (items: JQuery[]) => void;
  updatePosition: () => void;
}

type QPixelResponseJSON = {
  status: 'success' | 'failed',
  message?: string,
  errors?: string[]
}

type QPixelComment = {
  id: number
  created_at: string
  updated_at: string
  post_id: number
  content: string
  deleted: boolean
  user_id: number
  community_id: number
  comment_thread_id: number
  has_reference: false
  reference_text: string | null
  references_comment_id: string | null
}

interface QPixel {
  // private properties
  _filters?: Filter[] | null;
  _pendingUserResponse?: Promise<Response> | null;
  _popups?: Record<string, QPixelPopup>;
  _preferences?: UserPreferences | null;
  _user?: User | null;

  // private methods

  /**
   * Call _fetchPreferences but only the first time to prevent redundant HTTP requests
   */
  _cachedFetchPreferences?: () => Promise<void>;

  /**
   * Update local variable _preferences and localStorage with an AJAX call for the user preferences
   */
  _fetchPreferences?: () => Promise<void>;

  /**
   * FIFO-style fetch wrapper for /users/me requests
   */
  _fetchUser?: () => Promise<Response>;

  /**
   * Get an object containing the current user's preferences. Loads, in order of precedence, from local variable,
   * {@link localStorage}, or Redis via AJAX.
   * @returns JSON object containing user preferences
   */
  _getPreferences?: () => Promise<UserPreferences>;

  /**
   * Get the key to use for storing user preferences in localStorage, to avoid conflating users
   * @returns string the localStorage key
   */
  _preferencesLocalStorageKey?: () => string;

  /**
   * Set local variable _preferences and localStorage to new preferences data
   * @param data an object, containing the new preferences data
   */
  _updatePreferencesLocally?: (data: UserPreferences) => void;

  // public methods

  /**
   * Add a button to the Markdown editor.
   * @param $buttonHtml the HTML content that the button should show - just text, if you like, or
   *                    something more complex if you want to.
   * @param shortName a short name for the action that will be used as the title and aria-label attributes.
   * @param callback a function that will be passed as the click event callback.
   */
  addEditorButton?: ($buttonHtml: JQuery.htmlString, shortName: string, callback: () => void) => void;

  /**
   * Add a validator that will be called before creating a post.
   * callback should take one parameter, the post text, and should return an array in
   * the following format:
   *
   * [
   *   true | false,  // is the post valid for this check?
   *   [
   *     { type: 'warning', message: 'warning message - will not block posting' },
   *     { type: 'error', message: 'error message - will block posting' }
   *   ]
   * ]
   */
  addPrePostValidation?: (callback: PostValidator) => void;

  /**
   * Get the current CSRF anti-forgery token. Should be passed as the X-CSRF-Token header when
   * making AJAX POST requests.
   */
  csrfToken?: () => string;

  /**
   * Create a notification popup - not an inbox notification.
   * @param type the type to apply to the popup - warning, danger, etc.
   * @param message the message to show
   */
  createNotification?: (type: NotificationType, message: string) => void;

  /**
   * Get the word in a string that the given position is in, and the position within that word.
   * @param splat an array, containing the string already split by however you define a "word"
   * @param posIdx the index to search for
   * @returns the word the given position is in, and the position within that word
   */
  currentCaretSequence?: (splat: string[], posIdx: number) => [string, number];
  /**
   * Fetches default user filter for a given category
   * @param categoryId id of the category to fetch
   */
  defaultFilter?: (categoryId: string) => Promise<string>;
  deleteFilter?: (name: string, system?: boolean) => Promise<void>;
  filters?: () => Promise<Record<string, Filter>>;

  /**
   * Get the absolute offset of an element.
   * @param element the element for which to find the offset.
   * @returns element offset information
   */
  offset?: (element: HTMLElement) => ElementOffset;

  /**
   * Get a single user preference by name.
   * @param name the name of the requested preference
   * @param community is the requested preference community-local (true), or network-wide (false)?
   * @returns the value of the requested preference
   */
  preference?: (name: string, community?: boolean) => Promise<string>;

  /**
   * Replace the selected text in an input field with a provided replacement.
   * @param $field the field in which to replace text
   * @param text the text with which to replace the selection
   */
  replaceSelection?: ($field: JQuery<HTMLInputElement | HTMLTextAreaElement>, text: string) => void;
  setFilter?: (name: string, filter: Filter, category: string, isDefault: boolean) => Promise<void>;
  setFilterAsDefault?: (categoryId: string, name: string) => Promise<void>;

  /**
   * Set a user preference by name to the value provided.
   * @param name the name of the preference to set
   * @param value the value to set to - must respond to toString() for {@link localStorage} and Redis
   * @param community is this preference community-local (true), or network-wide (false)?
   */
  setPreference?: (name: string, value: unknown, community?: boolean) => Promise<void>;

  /**
   * Get the user object for the current user.
   * @returns JSON object containing user details
   */
  user?: () => Promise<User>;

  /**
   * Internal. Called just before a post is sent to the server to validate that it passes
   * all custom checks.
   */
  validatePost?: (postText: string) => [boolean, PostValidatorMessage[]];

  /**
   * Send a request with JSON data, pre-authorized with QPixel credentials for the signed in user.
   * @param uri The URI to which to send the request.
   * @param data An object containing data to send as the request body. Must be acceptable by JSON.stringify.
   * @param options An optional {@link RequestInit} to override the defaults provided by this method. 
   * @returns The Response promise returned from {@link fetch}.
   */
  fetchJSON?: (uri: string, data: any, options?: RequestInit) => Promise<Response>;

  /**
   * @param uri The URI to which to send the request.
   * @param options An optional {@link RequestInit} to override the defaults provided by {@link fetchJSON}
   * @returns 
   */
  getJSON?: (uri: string, options?: Omit<RequestInit, 'method'>) => Promise<Response>;

  /**
   * Attempts get a JSON reprentation of a comment
   * @param id id of the comment to get
   */
  getComment?: (id: string) => Promise<QPixelComment>

  /**
   * Attempts to dynamically load thread content
   * @param id id of the comment thread
   * @param options configuration options
   */
  getThreadContent?: (id: string, options?: {
    inline?: boolean,
    showDeleted?: boolean
  }) => Promise<string>

  /**
   * Attempts to dynamically load a list of comment threads for a given post
   * @param id id of the post to load
   */
  getThreadsListContent?: (id: string) => Promise<string>

  /**
   * Attempts to delete a comment
   * @param id id of the comment to delete
   * @returns result of the operation
   */
  deleteComment?: (id: string) => Promise<QPixelResponseJSON>

  /**
   * Attempts to undelete a comment
   * @param id id of the comment to undelete
   * @returns result of the operation
   */
  undeleteComment?: (id: string) => Promise<QPixelResponseJSON>

  /**
   * Attempts to lock a comment thread
   * @param id id of the comment thread to lock
   * @returns result of the operation
   */
  lockThread?: (id: string) => Promise<QPixelResponseJSON>;

  // qpixel_dom
  DOM?: QPixelDOM;
  Popup?: typeof QPixelPopup;
  // Stripe integration, TODO: types
  stripe?: any;
}

// Chartkick, TODO: types
declare var Chartkick: any;
declare var _CodidactKeyboard: QPixelKeyboard;
// Highlight.js lib, TODO: types
declare var hljs: any;
// MathJax lib, TODO: types
declare var MathJax: any;
// DOMPurify lib, TODO: types
declare var DOMPurify: any;
declare var QPixel: QPixel;

declare var getCaretCoordinates: (
  element: any,
  position: any,
  options: any
) => {
  top: number;
  left: number;
  height: number;
};

interface Window {
  mozInnerScreenX?: number;

  // MarkdownIt lib, TODO: types
  converter?: any;
  markdownit?: (...args: any[]) => any;
  markdownitFootnote?: (...args: any[]) => any;
}
