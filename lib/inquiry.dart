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
      return "Name is required";
    }

    final regex = RegExp(r'^[a-zA-Z ]+$');
    if (!regex.hasMatch(value.trim())) {
      return "Only alphabets allowed";
    }

    if (value.trim().split(" ").length < 2) {
      return "Enter full name";
    }

    return null;
  }

  String? validateMalaysiaPhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Contact is required";
    }

    final regex = RegExp(r'^01[0-9]{8,9}$');
    if (!regex.hasMatch(value)) {
      return "Invalid Malaysia phone number";
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
              title: const Text("Confirm Exit"),
              content: const Text(
                "Are you sure you want to leave this page? Your data will not be saved.",
              ),
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

  // ✅ SECTION 1
  Widget _section1() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          const Text("* Please select *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),

          RadioListTile<String>(
            value: "inquiries",
            groupValue: selectedType,
            title: const Text("Inquiries"),
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
            title: const Text("Dance Audition"),
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
                  const SnackBar(content: Text("Please select an option")),
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

  // ✅ SECTION 2
  Widget _section2() {
    return buildScrollableSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _inquiryFormKey,
          child: Column(
            children: [
              const Text("We will ask you some questions upon your inquiries in this section"),
      
              const SizedBox(height: 12),
      
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),
      
              const SizedBox(height: 12),
      
              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Contact Number",
                  border: OutlineInputBorder(),
                ),
                validator: validateMalaysiaPhone,
              ),
      
              const SizedBox(height: 12),
      
              TextFormField(
                controller: inquiryController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Your Inquiry",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
      
              const SizedBox(height: 12),
      
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
                      const SnackBar(
                        content: Text("Upload a document"),
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

  // ✅ SECTION 3
  Widget _section3() {
    return buildScrollableSection(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _auditionFormKey,
          child: Column(
            spacing: 14.0,
            children: [
              const Text("We will ask you some questions upon dance audition in this section"),
      
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),
      
              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Contact Number",
                  border: OutlineInputBorder(),
                ),
                validator: validateMalaysiaPhone,
              ),
      
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text("Do you have transportation?"),
                  ),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: hasTransport,
                      items: const [
                        DropdownMenuItem(value: "yes", child: Text("Yes")),
                        DropdownMenuItem(value: "no", child: Text("No")),
                      ],
                      onChanged: (value) {
                        setState(() => hasTransport = value);
                      },
                      validator: (v) => v == null ? "Required" : null,
                    ),
                  ),
                ],
              ),
      
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
                      const SnackBar(
                        content: Text("Upload a video"),
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

  // ✅ SECTION 4
  Widget _section4() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 14.0,
        children: [
          const Text(
            "Review & Submit",
            style: TextStyle(fontSize: 18),
          ),

          ListTile(
            title: const Text("Type"),
            subtitle: Text(selectedType ?? "-"),
          ),

          ListTile(
            title: const Text("Styles"),
            subtitle: Text(
              selectedStyles.isEmpty
                  ? "-"
                  : selectedStyles.join(", "),
            ),
          ),

          const Spacer(),

          if (isSubmitting) ...[
            const Text("Uploading..."),
            LinearProgressIndicator(value: uploadProgress),
          ],

          navigationButtons(
            onBack: previousPage,
            onNext: isSubmitting ? null : handleSubmit,
            nextText: "Submit",
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
    String nextText = "Next",
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onBack,
            child: const Text("Back"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onNext,
            child: Text(nextText),
          ),
        ),
      ],
    );
  }
}