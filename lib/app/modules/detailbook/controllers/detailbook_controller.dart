import 'dart:convert';

import 'package:booksphere/app/data/models/response_ulasan.dart';
import 'package:booksphere/app/data/models/response_peminjaman.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:booksphere/app/data/constans/endpoint.dart';
import 'package:booksphere/app/data/models/response_detailsbook.dart';
import 'package:booksphere/app/data/provider/api_provider.dart';
import 'package:booksphere/app/data/provider/storage_provider.dart';
import 'package:booksphere/app/modules/bookmark/controllers/bookmark_controller.dart';
import 'package:booksphere/app/modules/history/controllers/history_controller.dart';
import 'package:booksphere/app/routes/app_pages.dart';

class MyState<T1, T2> {
  T1? state1;
  T2? state2;
  // T3? state3;
  MyState({this.state1, this.state2});
}

class DetailbookController extends GetxController
    with StateMixin<MyState<DataBookDetails, List<DataUlasan>>> {
  //TODO: Implement DetailbookController
  final BookmarkController bookmarkController = Get.put(BookmarkController());
  
  final HistoryController historyController = Get.put(HistoryController());
  final detailBuku = DataBookDetails().obs;
  final TextEditingController ulasanController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxDouble ratingStar = 3.0.obs;
  final RxList<DataUlasan> ulasanBuku = <DataUlasan>[].obs;
  final judulBuku = "".obs;
  final count = 0.obs;
  final loading = false.obs;
  int get day => DateTime.now().day;
  int get month => DateTime.now().month;
  int get year => DateTime.now().year;
  DateTime get oneWeekFromNow => DateTime.now().add(const Duration(days: 7));
  int get dayAfter => oneWeekFromNow.day;
  int get monthAfter => oneWeekFromNow.month;
  int get yearAfter => oneWeekFromNow.year;
  final id = Get.parameters['idbook'];
  final idPinjam = 0.obs;
  @override
  void onInit() {
    super.onInit();
    getData();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;

  Future<void> getData() async {
    change(null, status: RxStatus.loading());

    try {
      final bearerToken = StorageProvider.read(StorageKey.bearerToken);
      final response = await ApiProvider.instance().get(
          '${Endpoint.book}/${id}',
          options: Options(headers: {"Authorization": "Bearer $bearerToken"}));
      final responseUlasanData = await ApiProvider.instance().get(
          '${Endpoint.ulasan}/${id}',
          options: Options(headers: {"Authorization": "Bearer $bearerToken"}));
      if (response.statusCode == 200 && responseUlasanData.statusCode == 200) {
        final ResponseDetailsbook responseDetailsbook =
            ResponseDetailsbook.fromJson(response.data);
        final ResponseUlasan responseUlasan =
            ResponseUlasan.fromJson(responseUlasanData.data);
        if (responseDetailsbook.data!.deskripsi!.isEmpty) {
          change(null, status: RxStatus.empty());
        } else {
          final newData = MyState(
              state1: responseDetailsbook.data, state2: responseUlasan.data);
          change(newData, status: RxStatus.success());
          detailBuku.value = responseDetailsbook.data!;
          ulasanBuku.value = responseUlasan.data!;
          judulBuku.value = responseDetailsbook.data!.judulBuku.toString();
        }
      } else {
        change(null, status: RxStatus.error("Gagal mengambil data"));
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.data != null) {
          change(null,
              status: RxStatus.error("${e.response?.data['message']}"));
        }
      } else {
        change(null, status: RxStatus.error(e.message ?? ""));
      }
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }

  addPinjam({String? idBuku}) async {
    loading(true);
    idBuku ??= id;
    try {
      final bearerToken = StorageProvider.read(StorageKey.bearerToken);
      String data = jsonEncode({"BukuID": idBuku});
      FocusScope.of(Get.context!).unfocus();
      final response = await ApiProvider.instance().post(Endpoint.pinjam,
          data: data,
          options: Options(headers: {"Authorization": "Bearer $bearerToken"}));

      if (response.statusCode == 200) {
        final ResponsePeminjaman responsePeminjaman =
            ResponsePeminjaman.fromJson(response.data);
        if (responsePeminjaman.message.toString() == "Buku Masih Di Pinjam") {
          loading(false);
          Navigator.pop(Get.context!, 'OK');
          Get.snackbar("Information", "Maaf Buku Anda Belum Anda Kembalikan",
              backgroundColor: Colors.red);
          // Get.offAllNamed(Routes.LOGIN);
          _showMyDialog(
            () {
              Navigator.pop(Get.context!, 'OK');
            },
            "Pemberitahuan",
            "Buku Masih Di Pinjam",
            "Ok",
          );
          return;
        }
        loading(false);
        historyController.getDataHistory();
        idPinjam.value = responsePeminjaman.data!.peminjamanID!;
        Navigator.pop(Get.context!, 'OK');
        Get.snackbar("Information", "Peminjaman Succes",
            backgroundColor: Colors.green);
        showSucsesPinjam();
        return;
      } else {
        Get.snackbar("Sorry", "Peminjaman Gagal", backgroundColor: Colors.red);
      }
      loading(false);
    } on DioException catch (e) {
      loading(false);
      if (e.response != null) {
        if (e.response?.data != null) {
          Get.snackbar("Sorry", "${e.response?.data['message']}",
              backgroundColor: Colors.red);
        }
      } else {
        Get.snackbar("Sorry", e.message ?? "", backgroundColor: Colors.red);
      }
    } catch (e) {
      loading(false);
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    }
  }

  addKoleksiBuku() async {
    if (detailBuku.value.koleksi == true) {
      _showMyDialog(
        () {
          Navigator.pop(Get.context!, 'OK');
        },
        "Pemberitahuan",
        "Buku ini sudah ada di koleksi",
        "Ok",
      );
      return;
    }
    try {
      FocusScope.of(Get.context!).unfocus();
      var userID = StorageProvider.read(StorageKey.idUser).toString();
      var bukuID = id;
      final bearerToken = StorageProvider.read(StorageKey.bearerToken);

      var response = await ApiProvider.instance().post(
        Endpoint.koleksi,
        options: Options(headers: {"Authorization": "Bearer $bearerToken"}),
        data: {
          "UserID": userID,
          "BukuID": bukuID,
        },
      );

      if (response.statusCode == 201) {
        bookmarkController.getDataKoleksi();
        String judulBukuDialog = judulBuku.value;
        _showMyDialog(
          () {
            Navigator.pop(Get.context!, 'OK');
          },
          "Buku berhasil disimpan",
          "Buku $judulBukuDialog berhasil disimpan di koleksi buku",
          "Oke",
        );
        getData();
      } else {
        _showMyDialog(
          () {
            Navigator.pop(Get.context!, 'OK');
          },
          "Pemberitahuan",
          "Buku gagal disimpan, silakan coba kembali",
          "Ok",
        );
      }
      loading(false);
    } on DioException catch (e) {
      loading(false);
      if (e.response != null) {
        if (e.response?.data != null) {
          _showMyDialog(
            () {
              Navigator.pop(Get.context!, 'OK');
            },
            "Pemberitahuan",
            "${e.response?.data?['message']}",
            "Ok",
          );
        }
      } else {
        _showMyDialog(
          () {
            Navigator.pop(Get.context!, 'OK');
          },
          "Pemberitahuan",
          e.message ?? "",
          "OK",
        );
      }
    } catch (e) {
      loading(false);
      _showMyDialog(
        () {
          Navigator.pop(Get.context!, 'OK');
        },
        "Error",
        e.toString(),
        "OK",
      );
    }
  }

  addUlasan() async {
    bool sudahMemberiUlasan = ulasanBuku.any((element) =>
        element.username.toString() ==
        StorageProvider.read(StorageKey.username));
    if (sudahMemberiUlasan) {
      _showMyDialog(
        () {
          Navigator.pop(Get.context!, 'OK');
        },
        "Pemberitahuan",
        "Anda sudah memberikan ulasan",
        "Ok",
      );
      return;
    }
    try {
      FocusScope.of(Get.context!).unfocus();
      formKey.currentState?.save();
      if (formKey.currentState!.validate()) {
        var bukuID = id;
        final bearerToken = StorageProvider.read(StorageKey.bearerToken);
        loading(true);
        var response = await ApiProvider.instance().post(
          Endpoint.ulasan,
          options: Options(headers: {"Authorization": "Bearer $bearerToken"}),
          data: {
            "Rating": ratingStar.value,
            "BukuID": bukuID,
            "Ulasan": ulasanController.text.toString()
          },
        );

        if (response.statusCode == 201) {
          ulasanController.clear();
          String judulBukuDialog = judulBuku.value;
          _showMyDialog(
            () {
              Navigator.pop(Get.context!, 'OK');
            },
            "Berhasil memberi ulasan",
            "Buku $judulBukuDialog berhasil diberi ulasan",
            "Oke",
          );
          getData();
        } else {
          _showMyDialog(
            () {
              Navigator.pop(Get.context!, 'OK');
            },
            "Pemberitahuan",
            "Ulasan gagal dikirim, silakan coba kembali",
            "Ok",
          );
        }
        loading(false);
      }
    } on DioException catch (e) {
      loading(false);
      if (e.response != null) {
        if (e.response?.data != null) {
          _showMyDialog(
            () {
              Navigator.pop(Get.context!, 'OK');
            },
            "Pemberitahuan",
            "${e.response?.data?['message']}",
            "Ok",
          );
        }
      } else {
        _showMyDialog(
          () {
            Navigator.pop(Get.context!, 'OK');
          },
          "Pemberitahuan",
          e.message ?? "",
          "OK",
        );
      }
    } catch (e) {
      loading(false);
      _showMyDialog(
        () {
          Navigator.pop(Get.context!, 'OK');
        },
        "Error",
        e.toString(),
        "OK",
      );
    }
  }

  Future<void> showMyPinjam() async {
    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0XFFFFFFFF),
          title: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFF09142E),borderRadius: BorderRadius.circular(10)),
              child: Text(
                "PEMINJAMAN BUKU",
                style: GoogleFonts.inriaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 20.0),
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Judul Buku",
                      style: GoogleFonts.inriaSans(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 16.0),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextFormField(
                      readOnly: true,
                      initialValue: detailBuku.value.judulBuku.toString(),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        isDense: true,
                        suffixIcon: const Icon(Icons.book),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nama",
                      style: GoogleFonts.inriaSans(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 16.0),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextFormField(
                      readOnly: true,
                      initialValue: StorageProvider.read(StorageKey.username),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        isDense: true,
                        suffixIcon: const Icon(Icons.people),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tanggal Pinjam",
                      style: GoogleFonts.inriaSans(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 16.0),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        isDense: true,
                        suffixIcon: const Icon(Icons.date_range),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                      ),
                      initialValue: "${day} - ${month} - ${year}",
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tanggal Kembali",
                      style: GoogleFonts.inriaSans(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 16.0),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        isDense: true,
                        suffixIcon: const Icon(Icons.date_range),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: Color(0xFF09142E)),
                        ),
                      ),
                      initialValue:
                          "${dayAfter} - ${monthAfter} - ${yearAfter}",
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  autofocus: true,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    animationDuration: const Duration(milliseconds: 300),
                  ),
                  onPressed: () => Navigator.pop(Get.context!, 'OK'),
                  child: Text(
                    "BACK",
                    style: GoogleFonts.inriaSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Obx(
                  () => TextButton(
                    autofocus: true,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0XFF000000),
                      animationDuration: const Duration(milliseconds: 300),
                    ),
                    onPressed: () {
                      addPinjam();
                    },
                    child: loading.value
                        ? const CircularProgressIndicator()
                        : Text(
                            "PINJAM",
                            style: GoogleFonts.inriaSans(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> showSucsesPinjam() async {
    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0XFFFFFFFF),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF09142E),
                    size: 200,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Center(
                  child: Text(
                    "BERHASIL !",
                    style: GoogleFonts.inriaSans(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF09142E),
                        fontSize: 26.0),
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
                Center(
                  child: Text(
                    "NOTE !",
                    style: GoogleFonts.inriaSans(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        fontSize: 26.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                  child: Text(
                    "Harap segera ke Perpustakaan untuk mengambil buku beserta menyerahkan bukti laporan",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inriaSans(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontSize: 17.0),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  autofocus: true,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF09142E),
                    animationDuration: const Duration(milliseconds: 300),
                  ),
                  onPressed: () {
                    Navigator.pop(Get.context!, 'OK');
                    Get.toNamed(Routes.PINJAM, parameters: {"idPinjam" : idPinjam.value.toString()});
                  },
                  child: Text(
                    "Generate laporan",
                    style: GoogleFonts.inriaSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

Future<void> _showMyDialog(
    final onPressed, String judul, String deskripsi, String nameButton) async {
  return showDialog<void>(
    context: Get.context!,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0XFFFFFFFF),
        title: Text(
          'BookSphere',
          style: GoogleFonts.inriaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20.0,
            color: const Color(0xFFEA1818),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                judul,
                style: GoogleFonts.inriaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    fontSize: 20.0),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                deskripsi,
                style: GoogleFonts.inriaSans(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 16.0),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            autofocus: true,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0XFFE14892),
              animationDuration: const Duration(milliseconds: 300),
            ),
            onPressed: onPressed,
            child: Text(
              nameButton,
              style: GoogleFonts.inriaSans(
                fontSize: 18.0,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ],
      );
    },
  );
}
