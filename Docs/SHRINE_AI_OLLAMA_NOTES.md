# Shrine AI And Ollama Notes

Status: optional future provider.  
Last updated: 2026-05-29

## Principle

Shrine must work with AI disabled. Deterministic behavior comes first.

Ollama may later help generate expressive but bounded behavior, but it is not required for Shrine MVP and must be disabled by default.

## Provider Shape

Add a `NoxShrineBehaviorProvider` protocol later. Providers return structured behavior packets only.

Suggested providers:

- `NoxDeterministicShrineBehaviorProvider`: default.
- `NoxOllamaShrineBehaviorProvider`: optional/stubbed, off by default.

## Ollama Constraints

Ollama provider must include:

- availability check;
- startup-independent fallback;
- timeout;
- deterministic fallback packet;
- Intel/Apple Silicon notes;
- no app launch dependency;
- settings gate;
- privacy gate.

AI output may only fill:

- face state;
- animation;
- sound cue;
- optional short text;
- urgency;
- allowed actions.

AI output must not:

- directly control hardware;
- bypass auto-summon/notification gates;
- produce free-form voice;
- produce long monologues;
- act as a chat assistant;
- make surveillance-like claims.

## Voice

Premade sound effects are preferred. Free-form voice LLM is not default because it risks making Shrine feel invasive.

## Tests

- AI disabled by default.
- deterministic provider works without Ollama installed.
- timeout falls back to deterministic packet.
- AI cannot create interrupt urgency without an allowed deterministic trigger.
- AI cannot introduce actions outside the allowed action set.
