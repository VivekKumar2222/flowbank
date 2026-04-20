import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Bank Cards Skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: [
                _skeletonBox(height: 160),
                // const SizedBox(height: 16),
                // _skeletonBox(height: 160),
              ],
            ),
          ),

          // const SizedBox(height: 30),

          // // Transactions Title Skeleton
          // Shimmer.fromColors(
          //   baseColor: Colors.grey.shade300,
          //   highlightColor: Colors.grey.shade100,
          //   child: _skeletonBox(height: 20, width: 180),
          // ),

          // const SizedBox(height: 16),

          // // Transactions List Skeleton
          // Shimmer.fromColors(
          //   baseColor: Colors.grey.shade300,
          //   highlightColor: Colors.grey.shade100,
          //   child: Column(
          //     children: List.generate(
          //       4,
          //       (index) => Padding(
          //         padding: const EdgeInsets.only(bottom: 12),
          //         child: Row(
          //           children: [
          //             _circleSkeleton(),
          //             const SizedBox(width: 12),
          //             Expanded(
          //               child: _skeletonBox(height: 16),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _skeletonBox({double height = 20, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }}

//   Widget _circleSkeleton() {
//     return Container(
//       height: 40,
//       width: 40,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         shape: BoxShape.circle,
//       ),
//     );
//   }
// }