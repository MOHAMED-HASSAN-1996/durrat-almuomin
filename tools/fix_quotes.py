import pathlib, re
p = pathlib.Path(r"D:\New folder (11)\adhkar\lib\data\adhkar.dart")
t = p.read_text(encoding="utf-8")
# The previous script used single quotes for virtue/virtueEn values, but some English values contain apostrophes (e.g., servant's)
# Replace all virtue lines to use double quotes
def fix(m):
    key = m.group(1)
    val = m.group(2)
    # if val already contains double quotes, escape them
    val = val.replace('"', r'\"')
    return f'{key}: "{val}",'
# This pattern matches virtue: '...' (single quoted) - but note some values may contain ' inside and were broken, so the regex may not match cleanly.
# Better: match virtue: '  then capture until ', but with broken strings it's messy.
# Instead, redo from scratch: re-read virtues and rewrite? Simpler: just replace all single-quoted virtue lines that were correctly formed.
# Use a more permissive pattern for already-broken? Let's instead brute fix: the file currently has unterminated strings due to apostrophe.
# Easiest: restore from git? No git. We have the generated virtues list; rewrite the file patches again using double quotes from the start.

# So let's re-apply virtues correctly using double quotes from the beginning: undo and redo.
# Easiest: remove virtue lines and re-add correctly.

# Remove any virtue lines that exist (even broken)
t = re.sub(r"\s*virtue:.*\n", "\n", t)
t = re.sub(r"\s*virtueEn:.*\n", "\n", t)

virtues_morning = [
    ("مَنْ قَرَأَهَا إِذَا أَصْبَحَ أُجِيرَ مِنَ الْجِنِّ حَتَّى يُمْسِيَ، وَإِذَا أَمْسَى حَتَّى يُصْبِحَ", "Whoever recites it in the morning is protected from jinn until evening"),
    ("حِصْنٌ مِنَ الشَّيْطَانِ وَحِرْزٌ مِنَ السُّوءِ فِي يَوْمِهِ", "A shield from Satan and evil throughout the day"),
    ("ذِكْرٌ يَرْبِطُ الْقَلْبَ بِاللَّهِ فِي بَدْءِ النَّهَارِ", "Connects the heart to Allah at the start of the day"),
    ("سَيِّدُ الِاسْتِغْفَارِ — مَنْ قَالَهُ مُوقِنًا فَمَاتَ مِنْ يَوْمِهِ دَخَلَ الْجَنَّةَ", "The master of forgiveness — whoever says it with certainty and dies that day enters Paradise"),
    ("يَحْفَظُ اللَّهُ بِهِ الْعَبْدَ مِنْ شَرِّ نَفْسِهِ وَالشَّيْطَانِ", "Allah protects the servant from the evil of his soul and Satan"),
    ("مَنْ قَالَهَا سَبْعًا كَفَاهُ اللَّهُ مَا أَهَمَّهُ", "Whoever says it seven times, Allah will suffice him in what concerns him"),
    ("لَمْ يَضُرَّهُ شَيْءٌ فِي ذَلِكَ الْيَوْمِ", "Nothing will harm him on that day"),
    ("وَجَبَتْ لَهُ الْجَنَّةُ", "Paradise becomes obligatory for him"),
    ("يُصْلِحُ اللَّهُ بِهِ شَأْنَ الْعَبْدِ كُلَّهُ", "Allah rectifies all of the servants affairs"),
    ("تَجْدِيدٌ لِعَهْدِ الْإِسْلَامِ وَالتَّوْحِيدِ", "A renewal of the covenant of Islam and pure monotheism"),
    ("مَنْ قَالَهَا مِائَةً لَمْ يَأْتِ أَحَدٌ بِأَفْضَلَ مِمَّا جَاءَ بِهِ", "Whoever says it 100 times, none will bring better than what he brought"),
    ("تُكْتَبُ لَهُ بِعَدَدِ الْخَلْقِ وَزِنَةِ الْعَرْشِ", "Reward is written for him by the number of creation and weight of the Throne"),
    ("حِفْظٌ مِنْ كُلِّ شَرِّ مَخْلُوقٍ", "Protection from the evil of every created thing"),
    ("عَافِيَةٌ فِي الْبَدَنِ وَالسَّمْعِ وَالْبَصَرِ", "Well-being in body, hearing, and sight"),
    ("نَجَاةٌ مِنَ الْكُفْرِ وَالْفَقْرِ وَعَذَابِ الْقَبْرِ", "Salvation from disbelief, poverty, and the torment of the grave"),
    ("حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ", "His sins are removed even if like the foam of the sea"),
    ("كَانَ كَعِتْقِ عَشْرِ رِقَابٍ وَكُتِبَتْ لَهُ مِائَةُ حَسَنَةٍ", "Like freeing ten slaves; 100 good deeds written for him"),
    ("سُؤَالُ الْعَافِيَةِ — جَامِعٌ لِخَيْرَيِ الدُّنْيَا وَالْآخِرَةِ", "Asking for well-being — gathers the good of this world and the next"),
    ("يُذْهِبُ اللَّهُ بِهِ الْهَمَّ وَيَقْضِي الدَّيْنَ", "Allah removes anxiety and settles debt through it"),
    ("حِرْزٌ مِنَ الشَّيْطَانِ وَالشِّرْكِ", "A protection from Satan and from associating partners with Allah"),
    ("كِفَايَةٌ وَتَوَكُّلٌ — مَنْ قَالَهَا خَرَجَ كَافِيًا", "Sufficiency and trust — whoever says it leaves sufficed"),
]

virtues_evening = [
    ("حِصْنٌ لِلَّيْلِ مِنَ الشَّيْطَانِ وَالْمَكْرُوهِ", "A fortress for the night against Satan and harm"),
    ("تَسْلِيمُ الْقَلْبِ لِلَّهِ عِنْدَ الْمَسَاءِ", "Surrendering the heart to Allah at evening"),
    ("سَيِّدُ الِاسْتِغْفَارِ — مَنْ قَالَهُ مُوقِنًا فَمَاتَ مِنْ لَيْلَتِهِ دَخَلَ الْجَنَّةَ", "Master of forgiveness — dies that night enters Paradise"),
    ("يَحْفَظُ اللَّهُ بِهِ الْعَبْدَ إِذَا أَمْسَى", "Allah protects the servant when evening comes"),
    ("مَنْ قَالَهَا سَبْعًا كَفَاهُ اللَّهُ مَا أَهَمَّهُ فِي لَيْلَتِهِ", "Seven times suffices him for his night"),
    ("لَمْ يَضُرَّهُ شَيْءٌ فِي تِلْكَ اللَّيْلَةِ", "Nothing will harm him that night"),
    ("وَجَبَتْ لَهُ الْجَنَّةُ", "Paradise becomes obligatory for him"),
    ("حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ", "Sins removed even if like sea foam"),
    ("حِفْظٌ مِنْ كُلِّ شَرِّ مَخْلُوقٍ فِي اللَّيْلِ", "Protection from evil of every creature at night"),
    ("عَافِيَةٌ وَسَلَامَةٌ فِي اللَّيْلِ", "Well-being and safety through the night"),
    ("نَجَاةٌ مِنَ الْكُفْرِ وَعَذَابِ الْقَبْرِ فِي اللَّيْلِ", "Salvation from disbelief and grave torment at night"),
    ("تَجْدِيدُ الْفِطْرَةِ عِنْدَ الْمَسَاءِ", "Renewing the pure natural disposition at evening"),
    ("كَانَ كَعِتْقِ عَشْرِ رِقَابٍ", "Like freeing ten slaves"),
    ("تُكْتَبُ لَهُ بِعَدَدِ الْخَلْقِ وَزِنَةِ الْعَرْشِ — وَلَوْ فِي اللَّيْلِ", "Reward by number of creation and Throne weight — even at night"),
    ("سُؤَالُ الْعَافِيَةِ الشَّامِلِ فِي اللَّيْلِ", "Comprehensive well-being asked for at night"),
    ("يُذْهِبُ اللَّهُ بِهِ الْهَمَّ فِي اللَّيْلِ", "Allah removes anxiety at night through it"),
    ("كِفَايَةٌ وَتَوَكُّلٌ عِنْدَ الْمَبِيتِ", "Sufficiency and trust when retiring for the night"),
    ("حِرْزٌ مِنَ الشَّيْطَانِ وَالشِّرْكِ فِي اللَّيْلِ", "Protection from Satan and shirk at night"),
]

virtues = virtues_morning + virtues_evening
pattern = re.compile(r"(source:\s*\"[^\"]*\"|source:\s*'[^']*',)\s*\n(\s*audio:)")
# Actually source lines use single quotes: source: '...',
pattern = re.compile(r"(source:\s*'[^']*',)\s*\n(\s*audio:)")
idx=0
def repl(m):
    global idx
    ar,en = virtues[idx]
    idx+=1
    # use double quotes for virtue values to avoid single-quote conflict; escape double quotes if any
    ar_esc = ar.replace('"', '\\"')
    en_esc = en.replace('"', '\\"')
    return f"{m.group(1)}\n    virtue: \"{ar_esc}\",\n    virtueEn: \"{en_esc}\",\n{m.group(2)}"
new_t, n = pattern.subn(repl, t)
print(f"patched {n}")
if n != len(virtues):
    print("WARN")
p.write_text(new_t, encoding="utf-8")
print("wrote")
