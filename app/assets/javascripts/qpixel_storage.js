window.QPixel = window.QPixel || {};

QPixel.Storage = {
  get latestMigration() {
    return localStorage.getItem("qpixel.latest_storage_migration");
  },
  migrations: [],
  addMigration(migration) {
    this.migrations.push(migration);
    return this;
  },
  async runMigrations() {
    const { latestMigration, migrations } = this;

    const latestIndex = migrations.findIndex((m) => m.name === latestMigration);
    const pending = migrations.slice(latestIndex + 1);

    for (const migration of pending) {
      try {
        await migration.up();
      } catch (e) {
        console.warn(`[qpixel/storage] migration ${migration.name} error`, e);
        break;
      }
    }
  },
};

document.addEventListener("DOMContentLoaded", async () => {
  await QPixel.Storage.addMigration({
    name: "fix-user-preferences",
    async up() {
      localStorage.removeItem("qpixel.user_undefined_preferences");
    },
  }).runMigrations();
});
