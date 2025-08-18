window.QPixel ||= {};

(() => {
  class QPixelStorageMigrationSource {
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

  class QPixelStorage {
    /** @type {string} */
    #prefix;
    
    /**
     * @param {string} prefix storage prefix to avoid collisions
     */
    constructor(prefix) {
      this.#prefix = prefix;
      this.migrations = new QPixelStorageMigrationSource(this);
    }

    get prefix() {
      return this.#prefix;
    }
  }

  QPixel.Storage ||= new QPixelStorage('qpixel');
})();
