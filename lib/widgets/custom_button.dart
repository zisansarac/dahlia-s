// // lib/widgets/custom_button.dart

// import 'package:flutter/material.dart';
// import '../theme.dart'; // BU OLMALI

// class CustomButton extends StatelessWidget {
//   final String text;
//   final VoidCallback onPressed;

//   const CustomButton({required this.text, required this.onPressed, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppColors.primary,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         minimumSize: const Size(double.infinity, 50),
//       ),
//       onPressed: onPressed,
//       child: Text(
//         text,
//         style: AppTextStyles.button,
//       ), // BURASI ARTIK HATA VERMEYECEK
//     );
//   }
// }
