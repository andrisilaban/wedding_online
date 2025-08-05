class InvitationModel {
  final String? id;
  final String? userId;
  final String? themeId;
  final String? title;
  final String? slug;
  final String? preWeddingText;
  final String? groomFullName;
  final String? groomNickName;
  final String? groomTitle;
  final String? groomFatherName;
  final String? groomMotherName;
  final String? brideFullName;
  final String? brideNickName;
  final String? brideTitle;
  final String? brideFatherName;
  final String? brideMotherName;
  final String? isPublished;
  final String? paymentStatus;
  final String? packageId;
  final String? expiredAt;
  final String? createdAt;
  final String? updatedAt;

  InvitationModel({
    this.id,
    this.userId,
    this.themeId,
    this.title,
    this.slug,
    this.preWeddingText,
    this.groomFullName,
    this.groomNickName,
    this.groomTitle,
    this.groomFatherName,
    this.groomMotherName,
    this.brideFullName,
    this.brideNickName,
    this.brideTitle,
    this.brideFatherName,
    this.brideMotherName,
    this.isPublished,
    this.paymentStatus,
    this.packageId,
    this.expiredAt,
    this.createdAt,
    this.updatedAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'],
      userId: json['user_id'],
      themeId: json['theme_id'],
      title: json['title'],
      slug: json['slug'],
      preWeddingText: json['pre_wedding_text'],
      groomFullName: json['groom_full_name'],
      groomNickName: json['groom_nick_name'],
      groomTitle: json['groom_title'],
      groomFatherName: json['groom_father_name'],
      groomMotherName: json['groom_mother_name'],
      brideFullName: json['bride_full_name'],
      brideNickName: json['bride_nick_name'],
      brideTitle: json['bride_title'],
      brideFatherName: json['bride_father_name'],
      brideMotherName: json['bride_mother_name'],
      isPublished: json['is_published'],
      packageId: json['package_id'],
      paymentStatus: json['payment_status'],
      expiredAt: json['expired_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
