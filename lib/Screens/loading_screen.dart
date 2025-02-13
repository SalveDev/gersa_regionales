import 'package:flutter/material.dart';
import 'package:gersa_regionwatch/Providers/theme_provider.dart';
import 'package:gersa_regionwatch/Theme/theme.dart';
import 'package:provider/provider.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary(
            Theme.of(context).brightness == Brightness.dark),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: AppIcons.customIcon(context, size: 300, invertMode: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
