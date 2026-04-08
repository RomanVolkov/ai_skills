---
name: german-email-composer
description: "Compose polite, professional German emails and letters from bullet points. Use this whenever you need to write formal German correspondence — to government offices, service providers, medical professionals, businesses, or any formal contact. Provide key points you want to mention and context about the recipient, and the skill will assemble a complete, polite letter with appropriate greetings, body, and closing in German, plus an English translation for your reference."
---

# German Email/Letter Composer

Compose polite, professional German emails and letters from a list of key points.

## Input

The user provides:

1. **Context** about the correspondence:
   - Who they're writing to (e.g., "dentist office", "city government", "car service")
   - What the situation/purpose is
   - Any relevant details (e.g., reference numbers, dates, appointment needs)
   - Desired formality level (default: formal/Sie; user may note if less formal is acceptable)

2. **Bullet points** of what they want to communicate:
   - Key messages or requests
   - Specific information to include
   - Any questions or actions needed from recipient

## Output

Generate a complete German letter with two sections:

### 1. German Version (primary)
```
[Greeting]

[Body with all bullet points integrated naturally]

[Closing]

Roman Volkov
```

**Guidelines for German composition:**
- Use formal "Sie" and polite register by default
- If user mentions "less formal is okay", use "Sie" but slightly more conversational tone
- Structure body paragraphs logically around the bullet points (don't list them; weave them into prose)
- Use appropriate German business letter conventions:
  - Greeting: "Sehr geehrte Damen und Herren," or "Sehr geehrte/r [Name/Title]," if known
  - Closing: "Mit freundlichen Grüßen," or similar (adjust based on context)
  - Line breaks between sections
  - Signature: "Roman Volkov"
- Ensure polite, respectful tone throughout
- Include all points from the user's list in the body

### 2. English Translation (reference)
```
[Same structure as German, translated to English]

Roman Volkov
```

Translate the German faithfully so the user can verify they're satisfied with what was sent.

## Key Principles

- **Politeness first**: German business correspondence values formality and respect. Err on the side of formal unless explicitly told otherwise.
- **Natural flow**: Integrate bullet points into coherent paragraphs, not as a list.
- **Context-aware**: Adapt greetings and closings based on the type of recipient (government, service provider, medical, etc.).
- **Complete letter**: Always include greeting, body, and closing — output is ready to send.
- **User verification**: Provide English translation so the user can confirm accuracy before sending.
