import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'utils/image_responsive.dart';

class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final PageController _controller = PageController();

  int currentPage = 0;
  int flowIndex = 0;

  String? selectedType;
  final Set<String> selectedStyles = {};

  final _inquiryFormKey = GlobalKey<FormState>();
  final _auditionFormKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController inquiryController = TextEditingController();

  String? hasTransport;

  PlatformFile? inquiryFile;
  PlatformFile? auditionVideo;

  bool isSubmitting = false;
  double uploadProgress = 0;

  void resetForm() {
    nameController.clear();
    contactController.clear();
    inquiryController.clear();

    selectedType = null;
    hasTransport = null;

    inquiryFile = null;
    auditionVideo = null;

    selectedStyles.clear();

    goToFlowIndex(0);
  }

  Future<String> uploadFileToFirebase({
    required PlatformFile file,
    required String folder,
  }) async {
    final storage = FirebaseStorage.instance;

    final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";

    final ref = storage.ref().child("$folder/$fileName");

    final uploadTask = ref.putFile(File(file.path!));

    uploadTask.snapshotEvents.listen((event) {
      final progress = event.bytesTransferred / event.totalBytes;
      setState(() {
        uploadProgress = progress;
      });
    });

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> saveToFirestore({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final collectionName = type == "inquiries" ? "inquiries" : "dance_auditions";
    await firestore.collection(collectionName).add(data);
  }

  Future<void> handleSubmit() async {
    try {
      setState(() {
        isSubmitting = true;
        uploadProgress = 0;
      });

      String? fileUrl;
      String? videoUrl;

      if (selectedType == "inquiries") {
        fileUrl = await uploadFileToFirebase(
          file: inquiryFile!,
          folder: "inquiries_docs",
        );
      }

      if (selectedType == "audition") {
        videoUrl = await uploadFileToFirebase(
          file: auditionVideo!,
          folder: "audition_videos",
        );
      }

      Map<String, dynamic> data;

      if (selectedType == "inquiries") {
        data = {
          "name": nameController.text.trim(),
          "contact": contactController.text.trim(),
          "inquiry": inquiryController.text.trim(),
          "fileUrl": fileUrl,
          "createdAt": FieldValue.serverTimestamp(),
        };
      } else {
        data = {
          "name": nameController.text.trim(),
          "contact": contactController.text.trim(),
          "hasTransport": hasTransport,
          "videoUrl": videoUrl,
          "createdAt": FieldValue.serverTimestamp(),
        };
      }

      await saveToFirestore(
        type: selectedType!,
        data: data,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submitted successfully")),
      );

      resetForm();

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
        uploadProgress = 0;
      });
    }
  }

  Future<void> pickInquiryFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        inquiryFile = result.files.first;
      });
    }
  }

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        auditionVideo = result.files.first;
      });
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "name_required".tr();
    }

    final regex = RegExp(r'^[a-zA-Z ]+$');
    if (!regex.hasMatch(value.trim())) {
      return "only_alphabets_allowed".tr();
    }

    if (value.trim().split(" ").length < 2) {
      return "full_name_required".tr();
    }

    return null;
  }

  String? validateMalaysiaPhone(String? value) {
    if (value == null || value.isEmpty) {
      return "contact_number_required".tr();
    }

    final regex = RegExp(r'^01[0-9]{8,9}$');
    if (!regex.hasMatch(value)) {
      return "invalid_malaysia_phone_number".tr();
    }

    return null;
  }

  List<int> get flow {
    if (selectedType == "inquiries") {
      return [0, 1, 3];
    } else if (selectedType == "audition") {
      return [0, 2, 3];
    }
    return [0];
  }

  void goToFlowIndex(int index) {
    final page = flow[index];
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    setState(() {
      flowIndex = index;
      currentPage = page;
    });
  }

  void nextPage() {
    if (flowIndex < flow.length - 1) {
      goToFlowIndex(flowIndex + 1);
    }
  }

  void previousPage() {
    if (flowIndex > 0) {
      goToFlowIndex(flowIndex - 1);
    }
  }

  double get progress => (currentPage + 1) / 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("confirm_exit_title").tr(),
              content: const Text("confirm_exit_subtitle").tr(),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("cancel").tr(),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("yes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)).tr(),
                ),
              ],
            );
          },
        );

        if ((shouldExit ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("inquiries").tr(),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Section ${currentPage + 1} of 4",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(value: value);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _section1(),
                    _section2(),
                    _section3(),
                    _section4(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section1() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          const Text("please_select", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)).tr(),

          RadioListTile<String>(
            value: "inquiries",
            groupValue: selectedType,
            title: const Text("inquiries").tr(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
                flowIndex = 0;
              });
            },
          ),

          RadioListTile<String>(
            value: "audition",
            groupValue: selectedType,
            title: const Text("dance_audition").tr(),
            onChanged: (value) {
              setState(() {
                selectedType = value;
                flowIndex = 0;
              });
            },
          ),

          const Spacer(),

          navigationButtons(
            onBack: null,
            onNext: () {
              if (selectedType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text("please_select_an_option").tr()),
                );
                return;
              }
              nextPage();
            },
          ),
        ],
      ),
    );
  }

  Widget _section2() {
    return buildScrollableSection(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _inquiryFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Text ("inquiries_section").tr(),
              ),

              const Text("auth.please_provide_your_name", style: TextStyle(fontWeight: FontWeight.bold)).tr(),

              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "auth.your_answer".tr(),
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),

              const Text("auth.please_provide_your_contact", style: TextStyle(fontWeight: FontWeight.bold)).tr(),

              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "auth.your_answer".tr(),
                  border: OutlineInputBorder(),
                ),
                validator: validateMalaysiaPhone,
              ),

              const Text("auth.please_provide_your_inquiry", style: TextStyle(fontWeight: FontWeight.bold)).tr(),

              TextFormField(
                controller: inquiryController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "auth.your_answer".tr(),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "required".tr() : null,
              ),

              const Text("auth.please_upload_supporting_document", style: TextStyle(fontWeight: FontWeight.bold)).tr(),

              FileUploadCard(
                file: inquiryFile,
                onPick: pickInquiryFile,
                onRemove: () {
                  setState(() => inquiryFile = null);
                },
              ),
      
              const Spacer(),
      
              navigationButtons(
                onBack: previousPage,
                onNext: () {
                  if (!_inquiryFormKey.currentState!.validate()) return;
      
                  if (inquiryFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("auth.please_upload_a_document").tr(),
                      ),
                    );
                    return;
                  }
      
                  nextPage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section3() {
    return buildScrollableSection(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _auditionFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10.0,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Text("audition_section").tr(),
              ),

              const Text("auth.please_provide_your_name", style: TextStyle(fontWeight: FontWeight.bold)).tr(),

              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "auth.your_answer".tr(),
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),

              const Text("auth.please_provide_your_contact", style: TextStyle(fontWeight: FontWeight.bold)).tr(),
      
              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "auth.your_answer".tr(),
                  border: OutlineInputBorder(),
                ),
                validator: validateMalaysiaPhone,
              ),
      
              const Text("auth.do_you_have_transportation", style: TextStyle(fontWeight: FontWeight.bold)).tr(),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: "yes",
                      groupValue: hasTransport,
                      title: const Text("yes").tr(),
                      onChanged: (value) {
                        setState(() => hasTransport = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: "no",
                      groupValue: hasTransport,
                      title: const Text("no").tr(),
                      onChanged: (value) {
                        setState(() => hasTransport = value);
                      },
                    ),
                  ),
                ],
              ),

              const Text("auth.please_upload_your_dance_video", style: TextStyle(fontWeight: FontWeight.bold)).tr(),
      
              FileUploadCard(
                file: auditionVideo,
                isVideo: true,
                onPick: pickVideo,
                onRemove: () {
                  setState(() => auditionVideo = null);
                },
              ),
      
              const Spacer(),
      
              navigationButtons(
                onBack: previousPage,
                onNext: () {
                  if (!_auditionFormKey.currentState!.validate()) return;
      
                  if (auditionVideo == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("auth.please_upload_a_video").tr(),
                      ),
                    );
                    return;
                  }
      
                  nextPage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section4() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 14.0,
        children: [
          const Text(
            "auth.submit_form",
            style: TextStyle(fontSize: 16),
          ).tr(),

          const Spacer(),

          if (isSubmitting) ...[
            const Text("auth.uploading").tr(),
            LinearProgressIndicator(value: uploadProgress),
          ],

          navigationButtons(
            onBack: previousPage,
            onNext: isSubmitting ? null : handleSubmit,
            nextText: "auth.submit".tr(),
          ),
        ],
      ),
    );
  }

  Widget buildScrollableSection({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget navigationButtons({
    required VoidCallback? onBack,
    required VoidCallback? onNext,
    String nextText = "auth.next",
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onBack,
            child: const Text("auth.back").tr(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onNext,
            child: Text(nextText).tr(),
          ),
        ),
      ],
    );
  }
}