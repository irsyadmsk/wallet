import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:financial_recording/core.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final double appBarHeight = AppBar().preferredSize.height;
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text(
          "Sign In",
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: const [],
        backgroundColor: primaryColor,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height - appBarHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(44.0),
            topRight: Radius.circular(44.0),
          ),
          color: Colors.white,
        ),
        // padding: const EdgeInsets.only(left: 30.0, top: 30.0),
        child: SingleChildScrollView(
          controller: ScrollController(),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 30.0, top: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 20.0,
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "Hello there, sign in to manage your financial",
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),
              Center(
                child: Image.asset("assets/visual/key.png", fit: BoxFit.fill),
              ),

              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      QTextField(
                        label: "Email",
                        validator: Validator.email,
                        value: null,
                        onChanged: (value) {},
                      ),
                      QTextField(
                        label: "Password",
                        obscure: true,
                        validator: Validator.required,
                        suffixIcon: Icons.password,
                        value: null,
                        onChanged: (value) {},
                      ),
                      QButton(
                        label: "Login",
                        onPressed: () {
                          if (controller.formKey.currentState!.validate()) {}
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  InkWell(
                    onTap: () => Get.to(() => RegisterView()),
                    child: Text(
                      "Register now",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
