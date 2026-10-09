export const SoundsPlugin = async ({ $ }) => {
  const sounds = {
    "session.created": "start.wav",
    "permission.asked": "input.wav",
    "session.compacted": "compact.wav",
    "session.idle": "complete.wav",
  }
  return {
    event: async ({ event }) => {
      const file = sounds[event.type]
      if (file) {
        await $`paplay $HOME/.claude/sounds/${file}`.quiet().nothrow()
      }
    },
  }
}
