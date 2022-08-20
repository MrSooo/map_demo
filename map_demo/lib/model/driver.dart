//Driver model để dùng khi lấy data từ API về, với các hàm chuyển JSON thành object và ngược lại
class Driver {
  String? name;
  String? avatar;
  String? email;
  String? phone;
  String? geolocation;

  Driver({this.name, this.avatar, this.email, this.phone, this.geolocation});

  Driver.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    avatar = json['avatar'];
    email = json['email'];
    phone = json['phone'];
    geolocation = json['geolocation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['avatar'] = avatar;
    data['email'] = email;
    data['phone'] = phone;
    data['geolocation'] = geolocation;
    return data;
  }
}
