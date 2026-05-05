class CategoryModel {
  int? id;
  String? libCategDriver;
  String? flagCategDriver;
  String? codeCategDriver;
  String? createdAt;
  String? updatedAt;

  CategoryModel(
      {this.id,
      this.libCategDriver,
      this.flagCategDriver,
      this.codeCategDriver,
      this.createdAt,
      this.updatedAt});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    libCategDriver = json['lib_categ_driver'];
    flagCategDriver = json['flag_categ_driver'];
    codeCategDriver = json['code_categ_driver'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}
