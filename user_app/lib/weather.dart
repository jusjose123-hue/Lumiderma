import 'package:admin_app/homepage.dart';
import 'package:flutter/material.dart';

class Weather extends StatelessWidget {
  const Weather({super.key, required this.we, });

  final Map<String, dynamic> we;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
       
        title: Center(child: Text("WEATHER DETAILS",style: TextStyle(color: Colors.white,fontSize: 30),)),
            
        
      ),
      extendBodyBehindAppBar: true,
      body:
       Container(
        height: double.infinity,
        
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/3.jpg"),
            fit: BoxFit.cover,
            
        )),
         child: Column(
          
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Card(
              elevation: 30,
              margin: EdgeInsets.all(20),
              color: const Color.fromARGB(99, 255, 249, 249),
              child: Container(
                height: 500,
                width: 500,
                
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 100),
                     Row(
                      children: [
                        SizedBox(width: 55),
                        Text("City : ${we['city']}", style: TextStyle(fontSize: 30)),
                      ],
                    ),
                    
                    Row(
                      children: [
                        SizedBox(width: 50),  
                        Text("Temperature : ${we['temperature']}", style: TextStyle(fontSize: 30)),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 50),
                        Text("condition : ${we['condition']}", style: TextStyle(fontSize: 30)),
                      ],
                    ),
                       Row(
                      children: [
                        SizedBox(width: 50),
                        Text("humidity : ${we['humidity']}", style: TextStyle(fontSize: 30)),
                      ],
                    ),
                     Row(
                      children: [
                        SizedBox(width: 50),
                        Text("wind : ${we['wind']}", style: TextStyle(fontSize: 30)),
                      ],
                    ),
                     Row(
                      children: [
                        SizedBox(width: 50),
                        Text("date : ${we['date']}", style: TextStyle(fontSize: 30)),
                      ],
                    ),
                    SizedBox(height: 50),
                       Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black,),
                         child: TextButton(onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Homepage()));
                         }, child: Text("Back",style: TextStyle(color: Colors.white,fontSize: 20),)),
                       )
                      
                        
                    
         
                    
                  ],
                ),
              ),
            ),
          ],
               ),
       ),
    );
  }
}
