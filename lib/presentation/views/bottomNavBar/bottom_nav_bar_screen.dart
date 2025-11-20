// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heliumedu/presentation/bloc/bottombarBloc/bottom_bar_bloc.dart';
import 'package:heliumedu/presentation/bloc/bottombarBloc/bottom_bar_event.dart';
import 'package:heliumedu/presentation/bloc/bottombarBloc/bottom_bar_state.dart';
import 'package:heliumedu/utils/app_colors.dart';
import 'package:heliumedu/utils/app_size.dart';

class BottomNavBarScreen extends StatelessWidget {
  const BottomNavBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BottomNavigationBloc(),
      child: const BottomNavBarView(),
    );
  }
}

class BottomNavBarView extends StatelessWidget {
  const BottomNavBarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
        builder: (context, state) {
          return context
              .read<BottomNavigationBloc>()
              .widgetList[state.selectedIndex];
        },
      ),
      bottomNavigationBar:
          BlocBuilder<BottomNavigationBloc, BottomNavigationState>(
            builder: (context, state) {
              return SafeArea(
                bottom: true,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 9.v,
                    horizontal: 12.h,
                  ),
                  margin: EdgeInsets.symmetric(vertical: 9.v, horizontal: 12.h),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(33.adaptSize),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Home Nav Item
                      GestureDetector(
                        onTap: () => context.read<BottomNavigationBloc>().add(
                          NavigationTabChanged(0),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.v,
                            horizontal: 18.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 24,
                                color: whiteColor,
                              ),
                              SizedBox(height: 4.v),
                              Text(
                                'Calendar',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.adaptSize,
                                  fontWeight: FontWeight.w400,
                                  color: state.selectedIndex == 0
                                      ? whiteColor
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Classes Nav Item
                      GestureDetector(
                        onTap: () => context.read<BottomNavigationBloc>().add(
                          NavigationTabChanged(1),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.v,
                            horizontal: 18.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 24,
                                color: whiteColor,
                              ),
                              SizedBox(height: 4.v),
                              Text(
                                'Classes',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.adaptSize,
                                  fontWeight: FontWeight.w400,
                                  color: state.selectedIndex == 1
                                      ? whiteColor
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Material Nav Item
                      GestureDetector(
                        onTap: () => context.read<BottomNavigationBloc>().add(
                          NavigationTabChanged(2),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.v,
                            horizontal: 18.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.business_center,
                                size: 24,
                                color: whiteColor,
                              ),
                              SizedBox(height: 4.v),
                              Text(
                                'Materials',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.adaptSize,
                                  fontWeight: FontWeight.w400,
                                  color: state.selectedIndex == 2
                                      ? whiteColor
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Grades Nav Item
                      GestureDetector(
                        onTap: () => context.read<BottomNavigationBloc>().add(
                          NavigationTabChanged(3),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4.v,
                            horizontal: 18.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 24,
                                color: whiteColor,
                              ),
                              SizedBox(height: 4.v),
                              Text(
                                'Grades',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.adaptSize,
                                  fontWeight: FontWeight.w400,
                                  color: state.selectedIndex == 3
                                      ? whiteColor
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
