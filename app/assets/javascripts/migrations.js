document.addEventListener("DOMContentLoaded", async () => {
  /**
   * Non-idempotent fix (it's just a data error) for how user preferences are stored
   * @type {QPixelStorageMigration}
   */
  const fixUserPreferences = {
    name: "fix-user-preferences",
    async up() {
      localStorage.removeItem("qpixel.user_undefined_preferences");
    },
  };

  await QPixel.Storage?.addMigration(fixUserPreferences)?.runMigrations();
});
