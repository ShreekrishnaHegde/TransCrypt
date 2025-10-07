import 'package:flutter/material.dart';
import 'package:transcrypt/screens/register_screen.dart';
import 'package:transcrypt/service/AuthService/AuthGate.dart';
import 'package:transcrypt/service/AuthService/AuthService.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {
  final authService=AuthService();
  final _emailController=TextEditingController();
  final _passwordController=TextEditingController();

  bool _obscureText = true;

  InputDecoration buildInputDecoration(String labelText,IconData icon) {
    return InputDecoration(
      border: UnderlineInputBorder(),
      labelText: labelText,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(16.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF140447), width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }
  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Color(0xFF140447),
    minimumSize: Size(double.infinity,50),
    // padding: EdgeInsets.symmetric(horizontal: 100),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  void login() async{
    final email=_emailController.text;
    final password=_passwordController.text;
    try{
      await authService.signInWithEmailPassword(email, password);
      if(mounted){

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>AuthGate()),);
      }
    }
    catch(e){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final screen_height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        color: Colors.black87,
                        fontFamily: 'Poppins'
                    ),
                    children: [
                      const TextSpan(
                        text: "Hi, ",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(
                        text: "Welcome Back 👋\n",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: "Login to your account",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screen_height/15,),
                TextFormField(
                  controller: _emailController,
                  decoration:  buildInputDecoration("Enter your email", Icons.email),
                ),
                SizedBox(height: 30,),
                TextFormField(
                  obscureText: _obscureText,
                  controller: _passwordController,
                  decoration: buildInputDecoration("Enter the password", Icons.password).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: (){
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                  ),
                ),
                SizedBox(height: 30,),
                ElevatedButton(
                  style: raisedButtonStyle,
                  onPressed: login,
                  child: const Text(
                    "Login",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      style: ButtonStyle(
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                      ),
                      onPressed: (){
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Signup()));
                      },
                      child: const Text(
                        "SignUp",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF140447),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}