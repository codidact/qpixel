window.QPixel ||= {};

(() => {
  /**
   * @implements {QPixelStorageMigrationSource}
   */
  class StorageMigrationSource {
    /** @type {QPixelStorageMigration[]} */
    #migrations = [];

    /** @type {QPixelStorage} */
    #storage;

    /**
     * @param {QPixelStorage} storage
     */
    constructor(storage) {
      this.#storage = storage;
    }

    get #latestKey() {
      return `${this.#storage.prefix}.latest_storage_migration`;
    }

    get latest() {
      return localStorage.getItem(this.#latestKey);
    }

    set latest(name) {
      localStorage.setItem(this.#latestKey, name);
    }

    /**
     * @param {QPixelStorageMigration} migration
     */
    add(migration) {
      this.#migrations.push(migration);
      return this;
    }

    async migrate() {
      const { latest } = this;

      const latestIndex = this.#migrations.findIndex((m) => m.name === latest);
      const pending = this.#migrations.slice(latestIndex + 1);

      for (const migration of pending) {
        try {
          await migration.up(this.#storage);
          this.latest = migration.name;
        } catch (e) {
          console.warn(`[qpixel/storage] migration ${migration.name} error`, e);
          break;
        }
      }
    }
  }

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
      this.migrations = new StorageMigrationSource(this);
    }

    get prefix() {
      return this.#prefix;
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
      const serialized = typeof value === "string" ? value : JSON.stringify(value);
      localStorage.setItem(`${this.#prefix}.${key}`, serialized);
      return this;
    }
  }

  QPixel.Storage ||= new Storage("qpixel");
})();
