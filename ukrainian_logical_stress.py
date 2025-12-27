#!/usr/bin/env python3
import warnings

# Suppress noisy warnings
warnings.filterwarnings("ignore", message="TypedStorage is deprecated")
warnings.filterwarnings("ignore", message="urllib3 v2 only supports OpenSSL")

import sys
import argparse
import re
import os
import subprocess


# Python 3.9+ is required
if sys.version_info < (3, 9):
    print("--- ERROR: PYTHON_VERSION_TOO_OLD ---")
    print(f"Python 3.9 or higher is required. Your current version: {sys.version}")
    print("\nTo fix this on Windows, run this in PowerShell:")
    print("winget install -e --id Python.Python.3.11")
    print("\nTo fix this on macOS, run this in Terminal:")
    print("brew install python@3.11")
    print("\nAfter installing, restart your terminal or REAPER.")
    sys.exit(1)


def bootstrap():
    """Automatically installs dependencies if they are missing."""
    try:
        import spacy
    except ImportError:
        print("--- Ukrainian Logical Stress Tool: First Time Setup ---")
        print("Dependencies missing. Attempting to install 'spacy'...")

        packages = ["spacy"]

        # Base install command
        cmd = [
            sys.executable,
            "-m",
            "pip",
            "install",
            "--disable-pip-version-check",
        ] + packages

        try:
            # Try normal install
            subprocess.check_call(cmd)
        except subprocess.CalledProcessError:
            # Try with --break-system-packages for macOS/Linux system Python
            try:
                print("Standard install failed. Trying with --break-system-packages...")
                subprocess.check_call(cmd + ["--break-system-packages"])
            except subprocess.CalledProcessError as e:
                print("--- ERROR: DEPENDENCY_INSTALL_FAILED ---")
                print(f"\nError: Could not install dependencies automatically.")
                print(
                    f"Please try running manually: {sys.executable} -m pip install spacy"
                )
                sys.exit(1)

        print("\nspaCy installed successfully!")

        # Invalidate caches so the new package can be found
        import importlib

        importlib.invalidate_caches()

        # Also refresh site-packages for the current process
        import site
        from importlib import reload

        reload(site)

    # Now check for the Ukrainian language model
    try:
        import spacy

        try:
            nlp = spacy.load("uk_core_news_lg")
        except OSError:
            print("\n--- Downloading Ukrainian language model (uk_core_news_lg) ---")
            print("This is a one-time download (~500MB). Please wait...")

            cmd = [sys.executable, "-m", "spacy", "download", "uk_core_news_lg"]

            try:
                subprocess.check_call(cmd)
            except subprocess.CalledProcessError:
                # Try with --break-system-packages
                try:
                    print(
                        "Standard download failed. Trying with --break-system-packages..."
                    )
                    subprocess.check_call(cmd + ["--break-system-packages"])
                except subprocess.CalledProcessError:
                    print("--- ERROR: MODEL_DOWNLOAD_FAILED ---")
                    print(f"\nError: Could not download Ukrainian language model.")
                    print(
                        f"Please try running manually: {sys.executable} -m spacy download uk_core_news_lg"
                    )
                    sys.exit(1)

            print("\nUkrainian language model downloaded successfully!")
            print("Initializing the model (this may take a moment)...")
    except Exception as e:
        print(f"--- ERROR: UNEXPECTED_ERROR ---")
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)

    return True


# Run bootstrap before other imports
bootstrap()

import spacy
from spacy.tokens import Doc

# Register spaCy extensions for custom data
if not Doc.has_extension("stressed_indices"):
    Doc.set_extension("stressed_indices", default=set())

# Internal spaCy model instance
_nlp = None


def get_nlp():
    """Get or create the spaCy Ukrainian language model."""
    global _nlp
    if _nlp is None:
        print("Loading Ukrainian language model...")
        _nlp = spacy.load("uk_core_news_lg")
        print("Model loaded successfully!")
    return _nlp


# Service words and constraints
MERGE_POS = {"ADP", "PART", "CCONJ", "SCONJ"}
CLITICS = {
    "ті", "та", "то", "же", "би", "хай", "б", "ж", "бо", "но", "такі", "таки", 
    "жеж", "нехай", "куди", "що", "як", "де", "кудись", "десь", "якось", "якийсь",
    "колись", "ніби", "мов", "неначе", "ніж", "аж", "навіть", "ось", "ото", "он",
    "ген", "мовби", "мовбито", "начебто", "цебто", "тобто", "ні", "ані", "адже",
    "от", "га", "ні-ні", "так-так", "ледве", "навряд чи", "хиба", "аніж", "буцім",
    "мовбито", "немов", "немовби", "принаймні", "навряд", "хтозна", "казна", "бозна",
    "таки", "наче", "начебто", "ніби", "нібито", "же ж", "та й", "хоч", "тільки",
    "лиш", "лише", "аби", "або", "чи", "чи то", "тобто", "не має", "вже", "ж", "же", "адже"
}
INTERJECTIONS = {
    "хех", "хохо", "ахах", "ехех", "хтозна", "авжеж", "аякже", "егеж",
    "ааа", "аааа", "еее", "ееее", "ооо", "оооо", "ууу", "уууу", "ммм", "мммм",
    "оу", "воу", "фуф", "хм", "мм", "ага", "еге",
    "ох", "ах", "ой", "ех", "гей", "тук-тук", "дідько", "трясця", "ого", "агов", 
    "ото", "ба", "тю", "тс", "цить", "гей-гей", "овва", "прокляття", 
    "господи", "боже", "матері", "леле", "фу", "фе", "тьху", "хух", "хе", "хо", 
    "ов", "ну", "анічичирк", "гав", "мяу", "му", "бе", "ме", "ку-ку", "алло",
    "ура", "браво", "біс", "гвалт", "рятуйте", "ай-ай-ай", "ой-ой-ой", "е-е-е",
    "м-м-м", "а-а-а", "о-о-о", "у-у-у", "чорт", "хай йому грець", "цугцванг",
    "блін", "курва", "сука", "бля", "пиздець", "хуя", "єбать", "жерти", "падло",
    "наволоч", "покидьку", "сволото", "гнида", "курча", "трясця", "дідько",
    "отакої", "ба-бах", "хрясь", "дзинь", "бум", "клацання", "шух", "плиг", "тпру",
    "вйо", "ну-ну", "та-ак", "ось тобі й маєш", "будь ласка", "дякую", "прошу",
    "батюшки", "матір божа", "гм", "мда", "киць-киць", "цитьте", "гу", "аргх", "ц",
    "хаха", "хахаха", "хехе", "хехехе", "хіхі", "хіхіхі", "хохо", "ахах", "ехех"
}
VOCATIVE_NAMES = {
    "сею", "боме", "інспекторе", "мамо", "тату", "друже", "пане", "пані", "добродію", 
    "брате", "сестро", "сину", "доню", "лікарю", "вчителю", "колего", "командире", 
    "шефе", "люди", "хлопці", "хлопче", "дівчино", "коханий", "кохана", "рідна", 
    "рідний", "бабусю", "дідусю", "внуче", "тітко", "дядьку", "племіннику", 
    "сусіде", "друзі", "панове", "красуне", "герою", "юначе", "старий", "соколе",
    "сонечко", "рибко", "кицю", "любове", "доле", "серце", "душо", "світе",
    "суко", "курво", "виродку", "дурню", "ідіоте", "кретине", "бовдуре", "тварюко",
    "паскудо", "гнидо", "сволото", "наволоч", "мерзотнику", "покидьку",
    "громадянине", "господарю", "клієнте", "пацієнте", "свідку", "солдате",
    "лейтенанте", "капітане", "майоре", "полковнику", "генерале", "президенте",
    "міністре", "директоре", "професоре", "студенте", "майстре", "босе",
    "зіронько", "рибонько", "пташко", "квіточко", "золотко", "мила", "милий",
    "любий", "шановний", "вельмишановний", "братку", "сестричко", "соколе",
    "котику", "зайчику", "ластівко", "голубе", "красеню", "крале", "лебедю",
    "мірандо", "міранда", "таррані", "вілл", "вілле", "тріл", "трілле", "колінзе", "бабусю"
}

MANDATORY_STRESS_VERBS = {
    "затям", "затями", "подай", "тримай", "дивись", "слухай", "дихай", "купи", 
    "немає", "нема", "затямся", "чекай", "зачекай", "стій", "глянь", "бач", 
    "скажи", "йди", "біжи", "мовчи", "сядь", "встань", "візьми", "дивися",
    "слухай", "замовкни", "пустіть", "відпусти", "клич", "пиши", "читай",
    "співай", "танцюй", "грай", "бий", "тягни", "штовхай", "кидай", "неси",
    "вези", "веди", "лети", "пливи", "біжи", "стрибай", "шукай", "знайди",
    "бери", "дай", "покажи", "поверни", "зупинись", "пробач", "вибач",
    "дозволь", "допоможи", "врятуй", "захисти", "помстися", "вбий", "помри",
    "живи", "люби", "ненавидь", "віруй", "сподівайся", "чекай", "мрій",
    "стули", "пиздуй", "йди", "геть", "зникни", "вгамуйся", "замовкни",
    "завали", "заткнися", "від'їбись", "заїбав", "відвали", "дивися",
    "послухай", "гляньте", "зупиніться", "залишайся", "повертайся", "пам'ятай",
    "забудь", "спробуй", "почни", "закінчуй", "тримайся", "бережися", "увага",
    "слухай-но", "дивись-но", "глянь-но", "пильнуй", "зважай", "подумай",
    "вирішуй", "принеси", "віддай", "тримай-но", "чекай-но", "неси-но", "відійди",
    "сядь-но", "стій-но", "мовчи-но", "гаси", "гасіть", "беріть", "йдіть", "біжіть"
}

PRIORITY_NOUNS = {
    "хліб", "молоко", "масло", "вино", "справа", "їжа", "вода", "гроші", "час", 
    "правда", "одяг", "дім", "робота", "життя", "смерть", "любов", "війна", 
    "мир", "сонце", "земля", "небо", "море", "річка", "місто", "село", "країна",
    "мати", "батько", "дитина", "людина", "друг", "ворог", "слово", "мова",
    "книга", "вогонь", "вітер", "дощ", "сніг", "дорога", "шлях", "сила",
    "воля", "доля", "душа", "серце", "світло", "пітьма", "день", "ніч",
    "ранок", "вечір", "час", "хвилина", "мить", "перемога", "свобода",
    "право", "обов'язок", "майбутнє", "минуле", "вчора", "сьогодні", "завтра",
    "гріх", "закон", "спокій", "тиша", "крик", "вогонь", "лід", "кров", "сльози",
    "допомога", "небезпека", "шанс", "ризик", "мета", "ціль", "успіх", "провал",
    "помилка", "знання", "розум", "краса", "честь", "гідність", "влада", "закон"
}

PREDICATIVE_WORDS = {
    "треба", "варто", "слід", "необхідно", "потрібно", "можна", "не можна", 
    "важливо", "можливо", "заборонено", "дозволено", "годі"
}

MODAL_WORDS = {
    "повинен", "повинна", "повинні", "мати", "має", "хотів", "хоче", "мусити", 
    "може", "можу", "треба", "варто", "слід", "необхідно", "потрібно", "готова", 
    "готовий", "спроможний", "здатен", "належить", "мушу", "мусиш", "мусить",
    "мусимо", "мусите", "мусять", "хочеться", "вдається", "встиг", "зумій",
    "спробуй", "намагайся", "старайся", "хочу", "хочеш", "хочемо", "хочете",
    "важливо", "можливо", "не можна", "заборонено", "дозволено", "мусимо",
    "мрію", "бажаю", "прагну", "планую", "вмію", "встигаю", "надіюся"
}

INFINITIVE_WORDS = {
    "прийти", "йти", "триматися", "дихати", "пити", "їсти", "взяти", "купити", 
    "дихай", "сховатися", "зробити", "сказати", "мовчати", "їхати", "бачити", 
    "знати", "жити", "померти", "любити", "відчувти", "зрозуміти", "почути",
    "говорити", "слухати", "читати", "писати", "співати", "працювати", 
    "відпочивати", "грати", "виграти", "програти", "втекти", "залишитися",
    "повернутися", "знайти", "втратити", "дати", "брати", "чекати", "забути",
    "пам'ятати", "думати", "вірити", "сподіватися", "дякувати", "прощати",
    "вбивати", "рятувати", "шукати", "кликати", "дивитися", "слухатися", "спати",
    "допомагати", "захищати", "будувати", "вчитися", "вчити", "кричати"
}

SOUND_DESCRIPTIONS = {
    "рже",
    "сміх",
    "плач",
    "крик",
    "зітхання",
    "мовчання",
    "шум",
    "гул",
}

VERB_OVERRIDES = {
    "купи": "Дієслово (наказовий спосіб)",
    "дихай": "Дієслово (наказовий спосіб)",
    "затям": "Дієслово (наказовий спосіб)",
    "затями": "Дієслово (наказовий спосіб)",
    "подай": "Дієслово (наказовий спосіб)",
    "тримай": "Дієслово (наказовий спосіб)",
    "дивись": "Дієслово (наказовий спосіб)",
    "слухай": "Дієслово (наказовий спосіб)",
    "чекай": "Дієслово (наказовий спосіб)",
    "зачекай": "Дієслово (наказовий спосіб)",
    "стій": "Дієслово (наказовий спосіб)",
    "глянь": "Дієслово (наказовий спосіб)",
    "бач": "Дієслово (наказовий спосіб)",
    "скажи": "Дієслово (наказовий спосіб)",
    "йди": "Дієслово (наказовий спосіб)",
    "біжи": "Дієслово (наказовий спосіб)",
    "мовчи": "Дієслово (наказовий спосіб)",
    "сядь": "Дієслово (наказовий спосіб)",
    "встань": "Дієслово (наказовий спосіб)",
    "візьми": "Дієслово (наказовий спосіб)",
    "бачив": "Дієслово",
    "гаси": "Дієслово (наказовий спосіб)",
    "гасіть": "Дієслово (наказовий спосіб)",
    "терпиш": "Дієслово",
}
for inf in INFINITIVE_WORDS:
    if inf not in VERB_OVERRIDES:
        VERB_OVERRIDES[inf] = "Дієслово (інфінітив)"
for mod in MODAL_WORDS:
    if mod not in VERB_OVERRIDES:
        if mod in PREDICATIVE_WORDS:
            VERB_OVERRIDES[mod] = "Присудкове слово (категорія стану)"
        else:
            VERB_OVERRIDES[mod] = "Дієслово"

POS_MAP_UK = {
    "NOUN": "Іменник",
    "VERB": "Дієслово",
    "AUX": "Дієслово",
    "PROPN": "Власна назва",
    "ADJ": "Прикметник",
    "ADV": "Прислівник",
    "PRON": "Займенник",
    "DET": "Займенник",
    "ADP": "Прийменник",
    "PART": "Частка",
    "INTJ": "Вигук",
    "NUM": "Числівник",
    "SCONJ": "Сполучник",
    "CCONJ": "Сполучник",
}

ROLE_MAP_UK = {
    "nsubj": "Підмет",
    "nsubjpass": "Підмет",
    "obj": "Додаток",
    "dobj": "Додаток",
    "iobj": "Додаток",
    "conj": "Однорідний член",
    "advmod": "Обставина",
    "amod": "Означення",
    "nmod": "Додаток",
    "obl": "Додаток",
    "vocative": "Звернення",
    "root": "Присудок",
    "xcomp": "Присудок",
    "ccomp": "Присудок",
    "acomp": "Присудок",
}


def get_token_labels(token):
    """Generate list of Ukrainian labels for verbose mode."""
    text_low = token.text.lower()
    pos = token.pos_
    dep = token.dep_.lower()
    case = token.morph.get("Case")

    # 1. Base Category (Morphology)
    category = POS_MAP_UK.get(pos, pos)
    
    # Pronoun sub-classification
    if pos in {"PRON", "DET"}:
        personal_stems = {"я", "ми", "ти", "ви", "він", "вона", "воно", "вони", "себе", 
                          "мене", "мені", "нам", "нас", "тебе", "тобі", "вас", "вам", 
                          "йому", "ним", "ньому", "їй", "нею", "ній", 
                          "їм", "ними", "них"}
        if text_low in personal_stems:
            category = "Займенник (особовий)"
        elif text_low in {"його", "її", "їх", "їхній"}:
            if dep in {"nmod", "poss", "det", "possessive"} or (token.head.pos_ in {"NOUN", "PROPN"} and dep == "det"):
                category = "Займенник (присвійний)"
            else:
                category = "Займенник (особовий)"
        elif text_low in {"мій", "моя", "моє", "мої", "твій", "твоя", "твоє", "твої", "свій", "своя", "своє", "свої", "наш", "наша", "наше", "наші", "ваш", "ваша", "ваше", "ваші"}:
            category = "Займенник (присвійний)"
        elif text_low in {"цей", "ця", "це", "ці", "той", "та", "те", "ті", "такий", "така", "таке", "такі", "стільки"}:
            category = "Займенник (вказівний)"
        elif text_low in {"увесь", "вся", "все", "усі", "всі", "кожен", "кожна", "кожна", "кожні", "жоден", "жодна", "жодне", "жодні", "інший", "інша", "інше", "інші", "сам", "самий"}:
            category = "Займенник (визначальний)"
        elif text_low in {"хто", "що", "який", "яка", "яке", "які", "чий", "чия", "чиє", "чиї", "котрий", "котра", "котре", "котрі", "скільки"}:
            category = "Займенник (відносний)"
        elif text_low in {"хтось", "щось", "якийсь", "чиясь", "чийсь"}:
            category = "Займенник (неозначений)"

    # Morphology overrides
    if text_low in VERB_OVERRIDES:
        category = VERB_OVERRIDES[text_low]

    # 2. Non-syntactic Unit Detection (Vocatives, Interjections, Particles)
    # Vocatives
    is_vocative = "Voc" in case or text_low in VOCATIVE_NAMES or dep == "vocative"
    if not is_vocative:
        head = token.head
        if "Voc" in head.morph.get("Case") or head.text.lower() in VOCATIVE_NAMES or head.dep_ == "vocative":
            if dep in {"conj", "flat", "appos", "nmod"}: is_vocative = True
    if not is_vocative and pos == "PROPN":
        # Heuristics for names without proper case tagging
        if (token.i == 0 and token.i + 1 < len(token.doc) and token.doc[token.i + 1].text == ",") or \
           (token.i > 0 and token.doc[token.i - 1].text == "," and (token.i == len(token.doc)-1 or token.doc[token.i+1].is_punct)):
             if text_low not in INTERJECTIONS: is_vocative = True

    # Interjections
    is_scream = re.fullmatch(r'([аеиоуі])\1{2,}', text_low) is not None
    is_interjection = (text_low in INTERJECTIONS or pos == "INTJ" or is_scream)
    if is_interjection and pos in {"PRON", "DET", "NOUN", "PROPN"} and text_low not in {"господи", "боже", "чорт", "блін"} and not is_scream:
        is_interjection = False
    
    # Particles and Formulas
    is_formula = text_low in {"дякую", "будь ласка", "прошу", "дякуємо", "дякувати"}
    is_particle = pos == "PART" or text_low in CLITICS

    # 3. Syntactic Role Assignment
    role = ROLE_MAP_UK.get(dep, "")
    
    # Predicate Logic (Verbs, Predicatives, Naming Nouns)
    is_naming_noun = (pos in {"NOUN", "PROPN"} and (dep == "root" or dep == "attr" or dep == "conj") and 
                      (any(c.text.lower() == "це" for c in token.children) or (token.i > 0 and token.doc[token.i-1].text == "—")))
    is_predicative = text_low in PREDICATIVE_WORDS or text_low in MODAL_WORDS
    is_impersonal = text_low.endswith(("но", "то")) and (pos == "VERB" or pos == "ADJ") and not any(c.dep_.startswith("nsubj") for c in token.children)
    is_actual_verb = category.startswith("Дієслово") or is_impersonal or pos == "AUX"

    if is_actual_verb or is_predicative or is_naming_noun:
        role = "Присудок"
    elif dep == "root" and not is_naming_noun and not is_predicative:
        # Fallback for root nouns/pronouns to Case-based role refined below
        role = ""

    # Member role refinement (Subject/Object)
    if not role or role in {"Підмет", "Додаток"}:
        if "Nom" in case: role = "Підмет"
        elif case: role = "Додаток"
        else:
            # Fallback for root if case is missing
            if dep == "root":
                if pos == "ADV": role = "Обставина"
                else: role = "Підмет"

    # Non-member overrides (Precedence: Particle > Formula > Interjection > Vocative)
    if is_particle:
        role = ""
        category = "Заперечна частка" if text_low == "не" else "Частка"
        is_vocative = is_interjection = False
    elif is_formula:
        role = ""
        category = "Формула ввічливості"
        is_vocative = is_interjection = False
    elif is_interjection:
        role = ""
        category = "Вигук"
        is_vocative = False
    elif is_vocative:
        # Check for identity sentences "Це Тріл"
        if any(c.text.lower() in {"це", "то"} and c.dep_ in {"nsubj", "expl"} for c in token.children):
            is_vocative = False
            role = "Присудок"
        else:
            role = "Звернення"
            category = "Іменник (кличний відмінок)"

    # 4. Refinements (Compound, Substantivized)
    if role == "Присудок":
        has_verbal_child = any(c.dep_.lower() in {"xcomp", "csubj", "acomp", "xcomp:pred"} for c in token.children)
        is_verbal_child = dep in {"xcomp", "csubj", "acomp", "xcomp:pred"}
        head_is_modal = (token.head.text.lower() in MODAL_WORDS or token.head.pos_ in {"VERB", "AUX"} or 
                         token.head.text.lower() in PREDICATIVE_WORDS or token.head.pos_ == "AUX")
        if (has_verbal_child or (is_verbal_child and head_is_modal)):
            role = "Складений присудок"

    if pos == "ADJ" and dep in {"obj", "nsubj"} and not is_predicative and not is_vocative:
        category = "Іменник (субстантивований)"

    # Final labels assembly
    seen = set()
    cleaned_labels = []

    if token.i in token.doc._.stressed_indices:
        cleaned_labels.append("Головна частина")
        seen.add("Головна частина")

    for candidate in [role, category]:
        if candidate and candidate not in seen:
            if any(c.isascii() and c.isalpha() for c in candidate): continue
            if category.startswith("Дієслово") and candidate in {"Іменник", "Власна назва", "Підмет"}: continue
            cleaned_labels.append(candidate)
            seen.add(candidate)

    return cleaned_labels


def find_logical_stress(doc):
    """Finds logical stress indices based on expert rules."""
    candidates = []

    # Priority 4: Mandatory Stress (Requested verbs, Vocatives, Interjections)
    for t in doc:
        text_low = t.text.lower()
        if (
            text_low in MANDATORY_STRESS_VERBS
            or t.dep_ == "vocative"
            or text_low in INTERJECTIONS
            or text_low in VOCATIVE_NAMES
        ):
            candidates.append((t.i, 4))

    # Priority 3: Nouns & Objects
    for t in doc:
        text_low = t.text.lower()
        if (
            t.pos_ == "NOUN"
            or text_low in PRIORITY_NOUNS
        ) and text_low not in VERB_OVERRIDES:
            if t.dep_ in {
                "ROOT",
                "obj",
                "dobj",
                "conj",
                "nmod",
                "root",
                "nsubj",
                "nsubjpass",
            }:
                candidates.append((t.i, 3))

    # Priority 2: Other Verbs
    if not any(c[1] >= 3 for c in candidates):
        for t in doc:
            if t.pos_ == "VERB" or t.text.lower() in VERB_OVERRIDES:
                candidates.append((t.i, 2))

    if not candidates:
        return set()

    exclude = set()
    # Rule: Lists (only first and last nouns)
    noun_indices = sorted(list(set([c[0] for c in candidates if c[1] == 3])))
    if len(noun_indices) > 2:
        i = 0
        while i < len(noun_indices):
            chain = [noun_indices[i]]
            j = i + 1
            while j < len(noun_indices) and noun_indices[j] - chain[-1] <= 3:
                chain.append(noun_indices[j])
                j += 1
            if len(chain) > 2:
                for mid in chain[1:-1]:
                    exclude.add(mid)
            i = j

    # Rule: Modal Chain
    # We define infinitives and modals more broadly to catch all variants
    infinitives = [
        t.i
        for t in doc
        if t.morph.get("VerbForm") == ["Inf"]
        or t.text.lower() in INFINITIVE_WORDS
        or t.dep_ == "xcomp"
    ]
    modals = [
        t.i
        for t in doc
        if t.text.lower() in MODAL_WORDS
    ]

    if modals and infinitives:
        for m in modals:
            # If a modal is close to ANY infinitive, it MUST be excluded from logical stress
            if any(abs(m - inf) <= 3 for inf in infinitives):
                exclude.add(m)

    # Filter by priority
    final = set()
    # Sort for consistent processing: Priority desc, then Left-to-Right
    candidates.sort(key=lambda x: (x[1], -x[0]), reverse=True)

    for idx, p in candidates:
        if idx in exclude:
            continue

        is_too_close = False
        for existing_idx in final:
            if abs(idx - existing_idx) <= 1:
                # Expert Rule: Allow proximity if one is Priority 4 (Imperative) and other is Priority 3 (Noun)
                # This fixes "КУПИ ХЛІБ"
                idx_p = 0
                for c_idx, c_p in candidates:
                    if c_idx == idx:
                        idx_p = c_p
                        break
                ex_p = 0
                for c_idx, c_p in candidates:
                    if c_idx == existing_idx:
                        ex_p = c_p
                        break

                if (idx_p >= 4 and ex_p == 3) or (idx_p == 3 and ex_p >= 4):
                    # allowed
                    pass
                else:
                    is_too_close = True
                    break

        if not is_too_close:
            if p >= 3:
                final.add(idx)
            elif p >= 2 and not any(
                c[1] >= 3 for c in candidates if c[0] not in exclude
            ):
                final.add(idx)

    # 'НЕ' inheritance
    ne_add = {idx - 1 for idx in final if idx > 0 and doc[idx - 1].text.lower() == "не"}
    return final.union(ne_add)


def apply_logical_stress(text, verbose=True, uppercase=False):
    if not text or not text.strip():
        return text

    orig_text = text
    
    # 1. Identify all protected segments (tags, brackets) and accents in original text
    ignored_mask = [False] * len(orig_text)
    
    # Tags and Brackets
    for m in re.finditer(r"(?:<[^>]+>|(?:\([^)]+\)|\[[^\]]+\]|\*[^*]+\*))", orig_text):
        for idx in range(m.start(), m.end()):
            ignored_mask[idx] = True
            
    # Accents
    for i, char in enumerate(orig_text):
        if char == '\u0301':
            ignored_mask[i] = True

    # 2. Build nlp_text and mapping nlp_idx -> orig_idx
    nlp_text = ""
    mapping = [] # mapping[nlp_idx] = orig_idx
    
    i = 0
    while i < len(orig_text):
        if ignored_mask[i]:
            if orig_text[i] == '\u0301':
                i += 1
                continue
            else:
                # Replace the WHOLE tag/bracket run with a single space
                start_i = i
                while i < len(orig_text) and ignored_mask[i] and orig_text[i] != '\u0301':
                    i += 1
                
                if not nlp_text or nlp_text[-1] != " ":
                    nlp_text += " "
                    mapping.append(start_i)
                continue
        else:
            nlp_text += orig_text[i]
            mapping.append(i)
            i += 1
    mapping.append(len(orig_text))

    # 3. Analyze with spaCy
    doc = get_nlp()(nlp_text)
    doc._.stressed_indices = find_logical_stress(doc)

    # 4. Reconstruct using a cursor on orig_text
    output = []
    current_orig_idx = 0
    
    i = 0
    while i < len(doc):
        t = doc[i]
        token_orig_start = mapping[t.idx]
        
        # Add everything from original text before this token
        if current_orig_idx < token_orig_start:
            output.append(orig_text[current_orig_idx:token_orig_start])
            current_orig_idx = token_orig_start
        
        # Determine if this token starts a merged segment
        is_sho = t.text.lower() == "що" and t.pos_ not in {"SCONJ", "CCONJ"}
        is_ne = t.text.lower() == "не" and t.i in doc._.stressed_indices
        
        if not is_sho and not is_ne and t.pos_ in MERGE_POS:
            service = [t]
            j = i + 1
            while (
                j < len(doc)
                and (doc[j].pos_ in MERGE_POS or doc[j].is_space)
                and not doc[j].is_punct
            ):
                if not doc[j].is_space:
                    service.append(doc[j])
                j += 1
            
            if j < len(doc) and not doc[j].is_punct and not doc[j].is_space:
                head = doc[j]
                merged_tokens = service + [head]
                m_orig_start = mapping[merged_tokens[0].idx]
                m_orig_end = mapping[merged_tokens[-1].idx + len(merged_tokens[-1].text)]
                
                merged_output = []
                cur_m_orig = m_orig_start
                for mt in merged_tokens:
                    mt_start = mapping[mt.idx]
                    mt_end = mapping[mt.idx + len(mt.text)]
                    if cur_m_orig < mt_start:
                        merged_output.append(orig_text[cur_m_orig:mt_start])
                    mt_orig = orig_text[mt_start:mt_end]
                    if mt.i in doc._.stressed_indices and uppercase:
                        txt = mt_orig.upper()
                    elif mt.pos_ == "PROPN" or (mt.i == 0 and not uppercase):
                        txt = mt_orig
                    else:
                        txt = mt_orig.lower()
                    merged_output.append(txt)
                    cur_m_orig = mt_end
                
                combined_txt = "".join(merged_output)
                if verbose:
                    lbls = []
                    for mt in merged_tokens:
                        lbls.extend(get_token_labels(mt))
                    seen_lbls = set()
                    uniq = [l for l in lbls if not (l in seen_lbls or seen_lbls.add(l))]
                    if uniq:
                        combined_txt += "{" + ", ".join(uniq) + "}"
                
                output.append(combined_txt)
                current_orig_idx = m_orig_end
                i = j + 1
                continue

        # Single token processing
        t_nlp = t.text
        token_orig_end = mapping[t.idx + len(t_nlp)]
        t_orig = orig_text[token_orig_start:token_orig_end]
        
        if t.is_punct or t.is_space:
            output.append(t_orig)
        else:
            lbls = get_token_labels(t) if verbose else []
            if t.i in doc._.stressed_indices and uppercase:
                txt = t_orig.upper()
            elif t.pos_ == "PROPN" or (t.i == 0):
                txt = t_orig
            else:
                txt = t_orig.lower()
                
            if lbls:
                txt += "{" + ", ".join(lbls) + "}"
            output.append(txt)
        
        current_orig_idx = token_orig_end
        i += 1

    if current_orig_idx < len(orig_text):
        output.append(orig_text[current_orig_idx:])

    return "".join(output)


def process_srt(content, verbose=True, uppercase=False):
    """Processes SRT file content and applies logical stress to the subtitle text."""
    lines = content.splitlines()
    processed_lines = []

    # SRT state: 0=Index, 1=Time, 2=Text
    state = 0
    for line in lines:
        if not line.strip():
            processed_lines.append(line)
            state = 0
            continue

        if state == 0:
            if line.strip().isdigit():
                processed_lines.append(line)
                state = 1
            else:
                processed_lines.append(line)
        elif state == 1:
            if "-->" in line:
                processed_lines.append(line)
                state = 2
            else:
                processed_lines.append(line)
        elif state == 2:
            # Apply stress to the subtitle text
            processed_lines.append(
                apply_logical_stress(line, verbose=verbose, uppercase=uppercase)
            )

    return "\n".join(processed_lines)


def process_ass(content, verbose=True, uppercase=False):
    """Processes ASS file content and applies logical stress to the Dialogue lines."""
    lines = content.splitlines()
    processed_lines = []

    for line in lines:
        if line.startswith("Dialogue:"):
            # ASS format: Dialogue: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
            parts = line.split(",", 9)
            if len(parts) > 9:
                prefix = ",".join(parts[:9])
                text = parts[9]

                # Apply stress while preserving tags like {\pos(x,y)}
                items = re.split(r"(\{.*?\})", text)
                processed_items = []
                for item in items:
                    if item.startswith("{") and item.endswith("}"):
                        processed_items.append(item)
                    else:
                        processed_items.append(
                            apply_logical_stress(
                                item, verbose=verbose, uppercase=uppercase
                            )
                        )

                processed_lines.append(f"{prefix},{''.join(processed_items)}")
            else:
                processed_lines.append(line)
        else:
            processed_lines.append(line)

    return "\n".join(processed_lines)


def main():
    parser = argparse.ArgumentParser(
        description="Analyze logical stress in Ukrainian sentences."
    )
    parser.add_argument(
        "input", help="The input string, or path to a .srt/.ass/.txt file."
    )
    parser.add_argument("-o", "--output", help="Optional output file path.")
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        default=True,
        help="Detailed grammatical info (default: True).",
    )
    parser.add_argument(
        "--no-verbose",
        action="store_false",
        dest="verbose",
        help="Disable detailed grammatical info.",
    )
    parser.add_argument(
        "-u",
        "--uppercase",
        action="store_true",
        help="Uppercase logically stressed words (default: False).",
    )

    args = parser.parse_args()

    # Check if input is a file path
    if os.path.isfile(args.input):
        filename = args.input
        basename, ext = os.path.splitext(filename)
        ext = ext.lower()

        try:
            with open(filename, "r", encoding="utf-8") as f:
                content = f.read()

            if ext == ".srt":
                result = process_srt(
                    content, verbose=args.verbose, uppercase=args.uppercase
                )
            elif ext == ".ass":
                result = process_ass(
                    content, verbose=args.verbose, uppercase=args.uppercase
                )
            else:
                # Treat as plain text
                result = apply_logical_stress(
                    content, verbose=args.verbose, uppercase=args.uppercase
                )

            # Determine output path
            output_path = (
                args.output if args.output else f"{basename}_logical_stress{ext}"
            )

            with open(output_path, "w", encoding="utf-8") as f:
                f.write(result)

            print(f"--- SUCCESS ---")
            print(f"File processed successfully: {filename}")
            print(f"Result saved to: {output_path}")

        except Exception as e:
            print(f"--- ERROR ---")
            print(f"An error occurred while processing the file: {e}")
            sys.exit(1)
    else:
        # Treat input as a string
        result = apply_logical_stress(
            args.input, verbose=args.verbose, uppercase=args.uppercase
        )
        print("\nLogical stress analysis:")
        print("-" * 30)
        print(result)
        print("-" * 30)


if __name__ == "__main__":
    main()
