window.QPixel ||= {};

(() => {
  class QPixelStorageMigrationSource {
    #storageKey = 'qpixel.latest_storage_migration';

    /** @type {QPixelStorageMigration[]} */
    #migrations = [];

    get latest() {
      return localStorage.getItem(this.#storageKey);
    }

    set latest(name) {
      localStorage.setItem(this.#storageKey, name);
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
          await migration.up();
          this.latest = migration.name;
        } catch (e) {
          console.warn(`[qpixel/storage] migration ${migration.name} error`, e);
          break;
        }
      }
    }
  }

  class QPixelStorage {
    migrations = new QPixelStorageMigrationSource();
  }

  QPixel.Storage ||= new QPixelStorage();
})();
