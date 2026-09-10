import pathlib, re

p = pathlib.Path("D:/New folder (11)/adhkar/lib/data/adhkar.dart")
text = p.read_text(encoding="utf-8")

virtues_morning = [
    ("مَنْ قَرَأَهَا إِذَا أَصْبَحَ أُجِيرَ مِنَ الْجِنِّ حَتَّى يُمْسِيَ، وَإِذَا أَمْسَى حَتَّى يُصْبِحَ", "Whoever recites it in the morning is protected from jinn until evening"),
    ("حِصْنٌ مِنَ الشَّيْطَانِ وَحِرْزٌ مِنَ السُّوءِ فِي يَوْمِهِ", "A shield from Satan and evil throughout the day"),
    ("ذِكْرٌ يَرْبِطُ الْقَلْبَ بِاللَّهِ فِي بَدْءِ النَّهَارِ", "Connects the heart to Allah at the start of the day"),
    ("سَيِّدُ الِاسْتِغْفَارِ — مَنْ قَالَهُ مُوقِنًا فَمَاتَ مِنْ يَوْمِهِ دَخَلَ الْجَنَّةَ", "The master of forgiveness — whoever says it with certainty and dies that day enters Paradise"),
    ("يَحْفَظُ اللَّهُ بِهِ الْعَبْدَ مِنْ شَرِّ نَفْسِهِ وَالشَّيْطَانِ", "Allah protects the servant from the evil of his soul and Satan"),
    ("مَنْ قَالَهَا سَبْعًا كَفَاهُ اللَّهُ مَا أَهَمَّهُ", "Whoever says it seven times, Allah will suffice him in what concerns him"),
    ("لَمْ يَضُرَّهُ شَيْءٌ فِي ذَلِكَ الْيَوْمِ", "Nothing will harm him on that day"),
    ("وَجَبَتْ لَهُ الْجَنَّةُ", "Paradise becomes obligatory for him"),
    ("يُصْلِحُ اللَّهُ بِهِ شَأْنَ الْعَبْدِ كُلَّهُ", "Allah rectifies all of the servant's affairs"),
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
# Patch each Dhikr block: add virtue fields after source line
# Find all occurrences of "source: '...',\n    audio:"
pattern = re.compile(r"(source:\s*'[^']*',)\s*\n(\s*audio:)")
idx = 0
def repl(m):
    global idx
    if idx >= len(virtues):
        return m.group(0)
    ar, en = virtues[idx]
    idx += 1
    # escape single quotes in ar/en (none contain ')
    return f"{m.group(1)}\n    virtue: '{ar}',\n    virtueEn: '{en}',\n{m.group(2)}"

new_text, n = pattern.subn(repl, text)
print(f"patched {n} entries, expected {len(virtues)}")
if n != len(virtues):
    print("WARN count mismatch")
p.write_text(new_text, encoding="utf-8")
print("done")
