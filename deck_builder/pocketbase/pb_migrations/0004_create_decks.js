migrate((app) => {
  // --- DELETE OLD DECKS COLLECTION IF EXISTS ---
  const oldDecks = app.findCollectionByNameOrId("decks");
  if (oldDecks) {
    console.log("Deleting old decks collection...");
    app.delete(oldDecks);
  }

  // --- CREATE NEW DECKS COLLECTION ---
  const decks = new Collection({
    name: "decks",
    type: "base",
    system: false,
    fields: [
      {
        name: "deckName",
        type: "text",
        required: true,
        unique: false,
        presentable: true,
      },
      {
        name: "public",
        type: "bool",
        required: false,
        presentable: true,
      },
      {
        name: "decklist",
        type: "json",
        required: false,
        presentable: true,
      },
      {
        name: "userId",
        type: "text",
        required: true,
        unique: false,
        presentable: true,
        options: {
          min: null,
          max: 100,
          pattern: "",
        },
      },
    ],
  });

  app.save(decks);
  console.log("✅ New decks collection created with username and userId fields.");

}, (app) => {
  // --- ROLLBACK: DELETE THE DECKS COLLECTION ---
  const decks = app.findCollectionByNameOrId("decks");
  if (decks) {
    app.delete(decks);
    console.log("Deleted decks collection on rollback.");
  }
});
