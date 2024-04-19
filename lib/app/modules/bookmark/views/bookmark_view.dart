import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:booksphere/app/data/models/response_bookmark_book.dart';
import 'package:booksphere/app/routes/app_pages.dart';

import '../controllers/bookmark_controller.dart';

class BookmarkView extends GetView<BookmarkController> {
  const BookmarkView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final heightFullBody =
        MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Koleksi Book",style: TextStyle(color: Color(0xFFE33629)),),
        backgroundColor: const Color(0xFF09142E),
        centerTitle: true,
      ),
      body: controller.obx(
        (state) => SafeArea(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Obx(
              () => controller.dataBookmark.value
                  ? const Center(
                      child: Text("Tidak Ada Koleksi"),
                    )
                  : ListView.builder(
                      itemCount: controller.listKoleksi.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          onDismissed: (direction) async {
                            await controller.deleteKoleksi(
                                controller.listKoleksi[index].bukuID!.toInt());
                            if (controller.jumlahData.value == 0) {
                              await controller.getDataKoleksi();
                            }
                          },
                          confirmDismiss: (direction) {
                            return showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Confirm'),
                                    content: Text('Are you sure to delete ?'),
                                    actions: [
                                      Obx(
                                        () => ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                            child: controller.loading.value
                                                ? const CircularProgressIndicator()
                                                : const Text("Yes")),
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: Text('No')),
                                    ],
                                  );
                                });
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 10),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.amber,
                              size: 25,
                            ),
                          ),
                          key: Key(index.toString()),
                          // Mengatur geser dari kanan ke kiri saja
                          direction: DismissDirection.endToStart,
                          child: ContentKoleksi(
                            width: width,
                            heightFullBody: heightFullBody,
                            data: controller.listKoleksi[index],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContentKoleksi extends StatelessWidget {
  const ContentKoleksi({
    super.key,
    required this.width,
    required this.data,
    required this.heightFullBody,
  });

  final double width;
  final DataBookmark data;
  final double heightFullBody;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: width,
      height: heightFullBody * 0.2,
      margin: EdgeInsets.only(bottom: heightFullBody * 0.02),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(10)),
      child: GestureDetector(
        onTap: () => Get.toNamed(Routes.DETAILBOOK, parameters: {"idBook" : data.bukuID.toString()}),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: width * 0.24,
                height: heightFullBody * 0.17,
                child: Image.network(
                  data.coverBuku.toString(),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: SizedBox()),
                  Text(
                    data.judul.toString(),
                    style: TextStyle(
                        fontFamily:
                            GoogleFonts.poppins(fontWeight: FontWeight.w700)
                                .fontFamily,
                        fontSize: 30),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                  ),
                  const Expanded(child: SizedBox()),
                  Text(
                    data.penulis.toString(),
                    style: TextStyle(
                        fontFamily:
                            GoogleFonts.poppins(fontWeight: FontWeight.w400)
                                .fontFamily,
                        fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                  ),
                  Text(
                    data.penerbit.toString(),
                    style: TextStyle(
                        fontFamily:
                            GoogleFonts.poppins(fontWeight: FontWeight.w400)
                                .fontFamily,
                        fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                  ),
                  Text(
                    data.tahunTerbit.toString(),
                    style: TextStyle(
                        fontFamily:
                            GoogleFonts.poppins(fontWeight: FontWeight.w400)
                                .fontFamily,
                        fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                  ),
                  const Expanded(child: SizedBox()),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xff09142E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                    "Save",
                    style: TextStyle(
                        fontFamily:
                            GoogleFonts.poppins(fontWeight: FontWeight.w400)
                                .fontFamily,
                        fontSize: 20,color: Colors.white,),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                  ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
            const Expanded(child: Icon(Icons.bookmark_border_outlined, color: Colors.black,size: 40,)),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
