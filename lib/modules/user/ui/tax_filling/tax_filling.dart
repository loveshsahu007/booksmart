import 'package:booksmart/constant/exports.dart';
import 'package:get/get.dart';

import 'subpages/ai_deduction_screen.dart';
import 'subpages/docs_hub_screen.dart';

class TaxTabController extends GetxController with GetTickerProviderStateMixin {
  late TabController tabController;

  RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        currentIndex.value = tabController.index;
      }
    });
  }

  void changeTab(int index) {
    tabController.animateTo(index);
    currentIndex.value = index;
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}

class TexFillingSceen extends StatefulWidget {
  const TexFillingSceen({super.key});

  @override
  State<TexFillingSceen> createState() => _TexFillingSceenState();
}

class _TexFillingSceenState extends State<TexFillingSceen> {
  TaxTabController taxTabController = Get.put(TaxTabController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TabBar(
            controller: taxTabController.tabController,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 5),
            indicatorColor: Get.theme.colorScheme.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: 'Documents'),
              Tab(text: "AI Deduction"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: taxTabController.tabController,

              children: [TaxDocsHubScreen(), AIDeductionScreen()],
            ),
          ),
        ],
      ),
    );
  }
}
