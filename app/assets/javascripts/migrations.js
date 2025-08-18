document.addEventListener('DOMContentLoaded', async () => {
  /**
   * Non-idempotent fix (it's just a data error) for how user preferences are stored
   * @type {QPixelStorageMigration}
   */
  const fixUserPreferences = {
    name: 'fix-user-preferences',
    async up(storage) {
      storage.remove('user_undefined_preferences');
    },
  };

  await QPixel.Storage?.migrations?.add(fixUserPreferences)?.migrate();
});
