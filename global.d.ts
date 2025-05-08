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

interface QPixel {
  // private properties
  _filters?: Filter[] | null;
  _pendingUserResponse?: Promise<Response> | null;
  _popups?: Record<string, QPixelPopup>;
  _preferences?: UserPreferences | null;
  _user?: User | null;

  // private methods
  _cachedFetchPreferences?: () => Promise<void>;
  _fetchPreferences?: () => Promise<void>;
  _fetchUser?: () => Promise<Response>;
  _getPreferences?: () => Promise<UserPreferences>;
  _preferencesLocalStorageKey?: () => string;
  _updatePreferencesLocally?: (data: UserPreferences) => void;

  // public methods
  addEditorButton?: ($buttonHtml: JQuery.htmlString, shortName: string, callback: () => void) => void;
  addPrePostValidation?: (callback: PostValidator) => void;
  csrfToken?: () => string;
  createNotification?: (type: NotificationType, message: string) => void;
  currentCaretSequence?: (splat: string[], posIdx: number) => [string, number];
  defaultFilter?: (categoryId: string) => Promise<string>;
  deleteFilter?: (name: string, system?: boolean) => Promise<void>;
  filters?: () => Promise<Record<string, Filter>>;
  offset?: (element: HTMLElement) => ElementOffset;
  preference?: (name: string, community?: boolean) => Promise<string>;
  replaceSelection?: ($field: JQuery<HTMLInputElement | HTMLTextAreaElement>, text: string) => void;
  setFilter?: (name: string, filter: Filter, category: string, isDefault: boolean) => Promise<void>;
  setFilterAsDefault?: (categoryId: string, name: string) => Promise<void>;
  setPreference?: (name: string, value: unknown, community?: boolean) => Promise<void>;
  user?: () => Promise<User>;
  validatePost?: (postText: string) => [boolean, PostValidatorMessage[]];
  jsonPost?: (uri: string, data: any, options?: RequestInit) => Promise<Response>;

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
