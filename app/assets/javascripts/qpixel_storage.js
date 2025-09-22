window.QPixel ||= {};

(() => {
  /**
   * @implements {QPixelStorage}
   */
  class Storage {
    /** @type {string} */
    #prefix;

    /**
     * @param {string} prefix storage prefix to avoid collisions
     */
    constructor(prefix) {
      this.#prefix = prefix;
    }

    get prefix() {
      return this.#prefix;
    }

    /**
     * @param {string} key unprefixed storage key
     * @param {QPixelStorageGetOptions} [options] optional configuration
     */
    get(key, options = {}) {
      const value = localStorage.getItem(`${this.#prefix}.${key}`);

      if (value !== null && options.parse) {
        return JSON.parse(value);
      }

      return value;
    }

    /**
     * @param {string} key unprefixed storage key
     */
    remove(key) {
      localStorage.removeItem(`${this.#prefix}.${key}`);
      return this;
    }

    /**
     * @param {string} key unprefixed storage key
     * @param {unknown} value value to save
     */
    set(key, value) {
      const serialized = typeof value === 'string' ? value : JSON.stringify(value);
      localStorage.setItem(`${this.#prefix}.${key}`, serialized);
      return this;
    }
  }

  QPixel.Storage ||= new Storage('qpixel');
})();
