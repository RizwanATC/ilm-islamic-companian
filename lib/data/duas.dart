/// Everyday duas (doa harian) with Malay and English meanings.
class Dua {
  const Dua(this.title, this.arabic, this.latin, this.ms, this.en, this.source);
  final String title;
  final String arabic;
  final String latin;
  final String ms;
  final String en;
  final String source;
}

class DuaGroup {
  const DuaGroup(this.name, this.duas);
  final String name;
  final List<Dua> duas;
}

const duaGroups = [
  DuaGroup('Morning & evening', [
    Dua(
      'Morning remembrance',
      'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلّٰهِ، وَالْحَمْدُ لِلّٰهِ، لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ',
      "Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah",
      'Kami berpagi hari dan kerajaan milik Allah pada pagi ini. Segala puji bagi Allah. Tiada tuhan melainkan Allah, Yang Maha Esa, tiada sekutu bagi-Nya.',
      'We have entered the morning and the dominion belongs to Allah. All praise is for Allah. There is no god but Allah alone, with no partner.',
      'Muslim',
    ),
    Dua(
      'Evening remembrance',
      'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلّٰهِ، وَالْحَمْدُ لِلّٰهِ، لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ',
      "Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah",
      'Kami berpetang hari dan kerajaan milik Allah pada petang ini. Segala puji bagi Allah. Tiada tuhan melainkan Allah, Yang Maha Esa, tiada sekutu bagi-Nya.',
      'We have entered the evening and the dominion belongs to Allah. All praise is for Allah. There is no god but Allah alone, with no partner.',
      'Muslim',
    ),
    Dua(
      'Protection from all harm (3×)',
      'بِسْمِ اللّٰهِ الَّذِيْ لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيْعُ الْعَلِيْمُ',
      "Bismillahil-ladhi la yadurru ma'asmihi shay'un fil-ardi wa la fis-sama', wa huwas-sami'ul-'alim",
      'Dengan nama Allah yang bersama nama-Nya tiada sesuatu pun di bumi dan di langit dapat memberi mudarat, dan Dialah Yang Maha Mendengar lagi Maha Mengetahui.',
      'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing.',
      'Abu Dawud, Tirmidhi',
    ),
    Dua(
      'Sayyidul istighfar',
      'اَللّٰهُمَّ أَنْتَ رَبِّيْ لَا إِلٰهَ إِلَّا أَنْتَ، خَلَقْتَنِيْ وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوْذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوْءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوْءُ بِذَنْبِيْ فَاغْفِرْ لِيْ، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوْبَ إِلَّا أَنْتَ',
      "Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana 'abduk, wa ana 'ala 'ahdika wa wa'dika mastata't, a'udhu bika min sharri ma sana't, abu'u laka bini'matika 'alayya, wa abu'u bidhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa ant",
      'Ya Allah, Engkaulah Tuhanku, tiada tuhan melainkan Engkau. Engkau menciptakanku dan aku hamba-Mu. Aku berpegang pada janji-Mu sedaya upayaku. Aku berlindung kepada-Mu daripada keburukan perbuatanku. Aku mengakui nikmat-Mu kepadaku dan aku mengakui dosaku, maka ampunilah aku. Sesungguhnya tiada yang mengampunkan dosa melainkan Engkau.',
      'O Allah, You are my Lord, there is no god but You. You created me and I am Your servant. I keep Your covenant and promise as best I can. I seek refuge in You from the evil I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.',
      'Bukhari',
    ),
  ]),
  DuaGroup('Food', [
    Dua(
      'Before eating',
      'اَللّٰهُمَّ بَارِكْ لَنَا فِيْمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ',
      "Allahumma barik lana fima razaqtana wa qina 'adhaban-nar",
      'Ya Allah, berkatilah rezeki yang Engkau kurniakan kepada kami dan peliharalah kami daripada azab neraka.',
      'O Allah, bless what You have provided for us and protect us from the punishment of the Fire.',
      'Ibn as-Sunni',
    ),
    Dua(
      'If you forgot Bismillah',
      'بِسْمِ اللّٰهِ أَوَّلَهُ وَآخِرَهُ',
      'Bismillahi awwalahu wa akhirah',
      'Dengan nama Allah pada awalnya dan pada akhirnya.',
      'In the name of Allah, at its beginning and at its end.',
      'Abu Dawud, Tirmidhi',
    ),
    Dua(
      'After eating',
      'اَلْحَمْدُ لِلّٰهِ الَّذِيْ أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِيْنَ',
      "Alhamdu lillahil-ladhi at'amana wa saqana wa ja'alana muslimin",
      'Segala puji bagi Allah yang telah memberi kami makan dan minum, serta menjadikan kami orang Islam.',
      'All praise is for Allah who fed us, gave us drink, and made us Muslims.',
      'Abu Dawud, Tirmidhi',
    ),
  ]),
  DuaGroup('Sleep', [
    Dua(
      'Before sleeping',
      'بِاسْمِكَ اللّٰهُمَّ أَمُوْتُ وَأَحْيَا',
      'Bismika Allahumma amutu wa ahya',
      'Dengan nama-Mu ya Allah, aku mati dan aku hidup.',
      'In Your name, O Allah, I die and I live.',
      'Bukhari',
    ),
    Dua(
      'Waking up',
      'اَلْحَمْدُ لِلّٰهِ الَّذِيْ أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُوْرُ',
      "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
      'Segala puji bagi Allah yang menghidupkan kami setelah mematikan kami, dan kepada-Nya kami dibangkitkan.',
      'All praise is for Allah who gave us life after causing us to die, and to Him is the resurrection.',
      'Bukhari',
    ),
  ]),
  DuaGroup('Home & travel', [
    Dua(
      'Leaving the house',
      'بِسْمِ اللّٰهِ تَوَكَّلْتُ عَلَى اللّٰهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ',
      "Bismillah, tawakkaltu 'alallah, la hawla wa la quwwata illa billah",
      'Dengan nama Allah, aku bertawakal kepada Allah. Tiada daya dan kekuatan melainkan dengan Allah.',
      'In the name of Allah, I place my trust in Allah. There is no power and no strength except with Allah.',
      'Abu Dawud, Tirmidhi',
    ),
    Dua(
      'Entering the house',
      'بِسْمِ اللّٰهِ وَلَجْنَا، وَبِسْمِ اللّٰهِ خَرَجْنَا، وَعَلَى اللّٰهِ رَبِّنَا تَوَكَّلْنَا',
      "Bismillahi walajna, wa bismillahi kharajna, wa 'alallahi rabbina tawakkalna",
      'Dengan nama Allah kami masuk, dengan nama Allah kami keluar, dan kepada Allah Tuhan kami, kami bertawakal.',
      'In the name of Allah we enter, in the name of Allah we leave, and upon Allah our Lord we rely.',
      'Abu Dawud',
    ),
    Dua(
      'Riding a vehicle',
      'سُبْحَانَ الَّذِيْ سَخَّرَ لَنَا هٰذَا وَمَا كُنَّا لَهُ مُقْرِنِيْنَ، وَإِنَّا إِلَىٰ رَبِّنَا لَمُنْقَلِبُوْنَ',
      'Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila rabbina lamunqalibun',
      'Maha Suci Allah yang telah menundukkan kenderaan ini untuk kami, sedangkan kami tidak mampu menguasainya. Dan sesungguhnya kepada Tuhan kamilah kami akan kembali.',
      'Glory be to Him who has subjected this to us, and we could not have done it ourselves. And to our Lord we will surely return.',
      'Az-Zukhruf 43:13–14',
    ),
  ]),
  DuaGroup('Masjid & purity', [
    Dua(
      'Entering the masjid',
      'اَللّٰهُمَّ افْتَحْ لِيْ أَبْوَابَ رَحْمَتِكَ',
      'Allahummaf-tah li abwaba rahmatik',
      'Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu.',
      'O Allah, open for me the doors of Your mercy.',
      'Muslim',
    ),
    Dua(
      'Leaving the masjid',
      'اَللّٰهُمَّ إِنِّيْ أَسْأَلُكَ مِنْ فَضْلِكَ',
      'Allahumma inni as’aluka min fadlik',
      'Ya Allah, sesungguhnya aku memohon kurniaan-Mu.',
      'O Allah, I ask You of Your bounty.',
      'Muslim',
    ),
    Dua(
      'Entering the toilet',
      'اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
      "Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith",
      'Ya Allah, aku berlindung kepada-Mu daripada syaitan jantan dan syaitan betina.',
      'O Allah, I seek refuge in You from the male and female devils.',
      'Bukhari, Muslim',
    ),
    Dua(
      'Leaving the toilet',
      'غُفْرَانَكَ',
      'Ghufranak',
      'Aku memohon keampunan-Mu.',
      'I seek Your forgiveness.',
      'Abu Dawud, Tirmidhi',
    ),
  ]),
  DuaGroup('Everyday', [
    Dua(
      'Wearing clothes',
      'اَلْحَمْدُ لِلّٰهِ الَّذِيْ كَسَانِيْ هٰذَا وَرَزَقَنِيْهِ مِنْ غَيْرِ حَوْلٍ مِنِّيْ وَلَا قُوَّةٍ',
      'Alhamdu lillahil-ladhi kasani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah',
      'Segala puji bagi Allah yang memakaikan pakaian ini kepadaku dan mengurniakannya tanpa daya dan kekuatan daripadaku.',
      'All praise is for Allah who clothed me with this and provided it for me, without any power or strength from me.',
      'Abu Dawud, Tirmidhi',
    ),
    Dua(
      'When it rains',
      'اَللّٰهُمَّ صَيِّبًا نَافِعًا',
      "Allahumma sayyiban nafi'a",
      'Ya Allah, turunkanlah hujan yang bermanfaat.',
      'O Allah, let it be a beneficial rain.',
      'Bukhari',
    ),
    Dua(
      'For worry and sadness',
      'اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
      "Allahumma inni a'udhu bika minal-hammi wal-hazan",
      'Ya Allah, aku berlindung kepada-Mu daripada kerisauan dan kesedihan.',
      'O Allah, I seek refuge in You from worry and grief.',
      'Bukhari',
    ),
    Dua(
      'For more knowledge',
      'رَبِّ زِدْنِيْ عِلْمًا',
      "Rabbi zidni 'ilma",
      'Wahai Tuhanku, tambahkanlah ilmu kepadaku.',
      'My Lord, increase me in knowledge.',
      'Taha 20:114',
    ),
    Dua(
      'For parents',
      'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِيْ صَغِيْرًا',
      'Rabbir-hamhuma kama rabbayani saghira',
      'Wahai Tuhanku, kasihanilah mereka berdua sebagaimana mereka mendidikku semasa kecil.',
      'My Lord, have mercy on them as they raised me when I was small.',
      'Al-Isra 17:24',
    ),
    Dua(
      'Good in this life and the next',
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      "Rabbana atina fid-dunya hasanah, wa fil-akhirati hasanah, wa qina 'adhaban-nar",
      'Wahai Tuhan kami, berikanlah kami kebaikan di dunia dan kebaikan di akhirat, dan peliharalah kami daripada azab neraka.',
      'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
      'Al-Baqarah 2:201',
    ),
  ]),
];
