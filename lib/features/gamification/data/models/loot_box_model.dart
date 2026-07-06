enum ChestType { wooden, silver, gold, legendary }

enum RewardType { coin, key, badge, frame, theme, artifact }

enum RewardRarity { common, rare, epic, legendary }

class RewardItem {
  final RewardType type;
  final int amount; // For coins or keys
  final String id; // For unique badges/frames/themes/artifacts
  final String name;

  RewardItem({
    required this.type,
    this.amount = 1,
    this.id = '',
    this.name = '',
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'amount': amount,
    'id': id,
    'name': name,
  };

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
    type: RewardType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => RewardType.coin,
    ),
    amount: json['amount'] ?? 1,
    id: json['id'] ?? '',
    name: json['name'] ?? '',
  );
}

class Chest {
  final String id;
  final ChestType type;

  Chest({required this.id, required this.type});

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
  };

  factory Chest.fromJson(Map<String, dynamic> json) => Chest(
    id: json['id'] ?? '',
    type: ChestType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ChestType.wooden,
    ),
  );
}

class EncyclopediaRewardDef {
  final String id;
  final String name;
  final RewardType type;
  final RewardRarity rarity;
  final String description;

  const EncyclopediaRewardDef({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.description,
  });
}

const List<EncyclopediaRewardDef> allPossibleRewards = [
  // Badges (10)
  EncyclopediaRewardDef(
    id: 'badge_0',
    name: 'شارة البداية',
    type: RewardType.badge,
    rarity: RewardRarity.common,
    description: 'تُمنح لبدء رحلتك الإيمانية مع تطبيق رفيقي.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_1',
    name: 'شارة الفجر',
    type: RewardType.badge,
    rarity: RewardRarity.rare,
    description: 'تُمنح للمحافظة على صلاة الفجر في وقتها المحدد.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_2',
    name: 'شارة الجماعة',
    type: RewardType.badge,
    rarity: RewardRarity.rare,
    description: 'تُمنح للمحافظة على صلاة الجماعة في المسجد.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_3',
    name: 'شارة المثابرة',
    type: RewardType.badge,
    rarity: RewardRarity.epic,
    description: 'تُمنح عند الاستمرار في أداء الصلوات دون انقطاع.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_4',
    name: 'شارة النور',
    type: RewardType.badge,
    rarity: RewardRarity.common,
    description: 'تُمنح لقراءة القرآن الكريم وإضاءة يومك بنور الذكر.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_5',
    name: 'شارة الذاكرين',
    type: RewardType.badge,
    rarity: RewardRarity.common,
    description: 'تُمنح للمداومة على الأذكار اليومية صباحاً ومساءً.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_6',
    name: 'شارة الترتيل',
    type: RewardType.badge,
    rarity: RewardRarity.epic,
    description: 'تُمنح لترتيل وتدبر آيات كتاب الله عز وجل.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_7',
    name: 'شارة رمضان',
    type: RewardType.badge,
    rarity: RewardRarity.legendary,
    description: 'شارة مباركة تُمنح للمجتهدين في العبادة خلال الشهر الفضيل.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_8',
    name: 'شارة الصبر',
    type: RewardType.badge,
    rarity: RewardRarity.common,
    description: 'تُمنح عند قضاء الصلوات الفائتة بالصبر والاحتساب.',
  ),
  EncyclopediaRewardDef(
    id: 'badge_9',
    name: 'شارة التفوق',
    type: RewardType.badge,
    rarity: RewardRarity.legendary,
    description: 'تُمنح لمن حقق مرتبة عالية واستثنائية في الالتزام اليومي.',
  ),

  // Frames (5)
  EncyclopediaRewardDef(
    id: 'frame_0',
    name: 'إطار الخشب',
    type: RewardType.frame,
    rarity: RewardRarity.common,
    description: 'إطار خشبي بسيط وبديع لملفك الشخصي.',
  ),
  EncyclopediaRewardDef(
    id: 'frame_1',
    name: 'إطار الفضة',
    type: RewardType.frame,
    rarity: RewardRarity.rare,
    description: 'إطار فضي لامع يعكس التزامك المستمر.',
  ),
  EncyclopediaRewardDef(
    id: 'frame_2',
    name: 'إطار الذهب',
    type: RewardType.frame,
    rarity: RewardRarity.epic,
    description: 'إطار ذهبي براق مخصص للمتميزين.',
  ),
  EncyclopediaRewardDef(
    id: 'frame_3',
    name: 'إطار الياقوت',
    type: RewardType.frame,
    rarity: RewardRarity.epic,
    description: 'إطار فاخر مرصع بالياقوت الأحمر النادر.',
  ),
  EncyclopediaRewardDef(
    id: 'frame_4',
    name: 'إطار الأسطورة',
    type: RewardType.frame,
    rarity: RewardRarity.legendary,
    description: 'إطار أسطوري مهيب يشع بنور الطاعة والالتزام.',
  ),

  // Themes (3)
  EncyclopediaRewardDef(
    id: 'theme_0',
    name: 'المظهر الكلاسيكي',
    type: RewardType.theme,
    rarity: RewardRarity.common,
    description: 'المظهر الأصلي المريح والهادئ للعين.',
  ),
  EncyclopediaRewardDef(
    id: 'theme_1',
    name: 'المظهر الليلي الهادئ',
    type: RewardType.theme,
    rarity: RewardRarity.rare,
    description: 'مظهر داكن مهدئ للأعصاب في الأوقات المتأخرة والليلية.',
  ),
  EncyclopediaRewardDef(
    id: 'theme_2',
    name: 'المظهر الذهبي الفاخر',
    type: RewardType.theme,
    rarity: RewardRarity.legendary,
    description: 'مظهر ذهبي أنيق وعالي الجودة مستوحى من كسوة الكعبة المشرفة.',
  ),

  // Artifacts (5)
  EncyclopediaRewardDef(
    id: 'artifact_0',
    name: 'مسبحة العقيق',
    type: RewardType.artifact,
    rarity: RewardRarity.common,
    description: 'مسبحة مصنوعة من حجر العقيق اليماني الفاخر للتسبيح.',
  ),
  EncyclopediaRewardDef(
    id: 'artifact_1',
    name: 'سجادة أثرية',
    type: RewardType.artifact,
    rarity: RewardRarity.rare,
    description: 'سجادة صلاة منسوجة بنقوش وزخارف إسلامية عريقة.',
  ),
  EncyclopediaRewardDef(
    id: 'artifact_2',
    name: 'مصحف مذهب',
    type: RewardType.artifact,
    rarity: RewardRarity.epic,
    description: 'نسخة أثرية من القرآن الكريم بخط مذهب فريد وكبير.',
  ),
  EncyclopediaRewardDef(
    id: 'artifact_3',
    name: 'مسك الكعبة',
    type: RewardType.artifact,
    rarity: RewardRarity.legendary,
    description: 'زجاجة عطر تحتوي على طيب الكعبة المشرفة الأصيل والرائع.',
  ),
  EncyclopediaRewardDef(
    id: 'artifact_4',
    name: 'مكحلة قديمة',
    type: RewardType.artifact,
    rarity: RewardRarity.epic,
    description: 'مكحلة أثرية ترمز للسنن والتقاليد النبوية القديمة.',
  ),
];
