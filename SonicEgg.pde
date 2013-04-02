

//3D Spectrogram with Microphone Input

//press 'p' to pause view
//press 'v' to toggle view
//press 't' to toggle freq labels
//press 'f' to toggle fade effect
//press 'd' to toggle dB amplitude scale


//Modified by Evan Morgan 2013 - http://you-rhythmic.com
//Based on version modified by kylejanzen 2011 - http://kylejanzen.wordpress.com
//Original script wwritten by John Locke 2011 - http://gracefulspoon.com


import processing.opengl.*;
import ddf.minim.analysis.*;
import ddf.minim.*;


FFT fftLog;

Waveform audio3D;

Minim minim;
AudioInput microphone;
boolean done = false;
boolean pause = false;
boolean altV = false; // toggle alternative view
boolean dB = true; // toggle display in dB
boolean fade = true; // toggle fade
boolean tex = true;

int depth = 220;
int Amp = 5;
int low = 220; //smallest octave Hz
int divi = 8; //divides octave by div
float cut = 0.06; //cut low level noise when in dB mode

PFont font;
int[] freqs = new int[0];
float[] levs = new float[1200];
int l = 0;

float camzoom;
float maxX = 0;
float maxY = 0;
float maxZ = 0;
float minX = 0;
float minY = 0;
float minZ = 0;

// choose sample frequency
int sf = 16000;
//int sf = 22050;
//int sf = 32000;
//int sf = 44100;


void setup()
{
  frame.setBackground(new java.awt.Color(0, 0, 0));
  size(1280, 720, OPENGL); //screen proportions
  smooth();
  noStroke();
  minim = new Minim(this);
  microphone = minim.getLineIn(Minim.MONO, 1024, sf); //repeat the song
  frameRate(100);
  background(255);
  font = createFont("Arial", 16, true);
  fftLog = new FFT(microphone.bufferSize(), microphone.sampleRate());
  fftLog.logAverages(low, divi);  //adjust numbers to adjust spacing;


  float w = float (width/fftLog.avgSize());
  float x = w;
  float y = 0;
  float z = 50;
  float radius = 10;
  audio3D = new Waveform(x, y, z, radius);
}
void draw()
{
  background(0);
  //println(fftLog.getAvg(20));

  


  arrayCopy(levs, 1, levs, 0, 1199);
  levs[1199] = microphone.left.level();

  l += 1;
  if (l == 1200)
    l = 0;





  pushMatrix();
  camera(width/2.0, height/2.0, (height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);
  //if (!altV)
    //image(a, 0, height-170);
  //else
    //image(a, 0, 0);

  for (int k =0; k<1200; k++) {
    stroke(255, 255, 255, k/(1200/255));
    strokeWeight(1);
    int a = constrain(round(levs[k]*200), 0, 50);
    if (altV)
      line(40+k, (90)-a, 40+k, (90)+1+a);
  }
  popMatrix();

  fftLog.window(FFT.HAMMING);

  float zoom = 250;
  int zoom2 =-100;
  PVector foc = new PVector(audio3D.x, audio3D.y, 0);
  PVector cam = new PVector(zoom, zoom, -zoom);

  if (!altV)
    camera(foc.x+cam.x+10+zoom2+3, foc.y+cam.y-50+zoom2-3, foc.z+cam.z+150-zoom2-120, foc.x+17, foc.y-40, foc.z, 0, 0, 1);
  else
    camera(round(width/2.0)-30, foc.y+cam.y+100, foc.z+cam.z-200, width/2.0-30, foc.y-100, foc.z-140, 0, 0, 1);

  directionalLight(255,255,255,sin(radians(-90)),cos(radians(180)),1);
  ambientLight(100,100,100,audio3D.x,audio3D.y,audio3D.z);

  //run fft on input
  fftLog.forward(microphone.mix);


  if (done == false) {
    done = true;
    for (int j =0; j<fftLog.avgSize(); j++) {
      freqs = expand(freqs, freqs.length+1);
      freqs[j] = round(fftLog.getAverageCenterFrequency(j));//round(b+((t-1)*(b/divi2))+((b/divi2)/2.0)) ;    
    }
  } 

//println(freqs[55]);

  audio3D.update();

  audio3D.textdraw();

  audio3D.plotTrace();
}

class Waveform
{
  float x, y, z;
  float radius;

  PVector[] pts = new PVector[fftLog.avgSize()];

  PVector[] trace = new PVector[0];


  Waveform(float incomingX, float incomingY, float incomingZ, float incomingRadius)
  {
    x = incomingX;
    y = incomingY;
    z = incomingZ;
    radius = incomingRadius;
  }
  void update()
  {
    plot();
  }
  void plot()
  {
    for (int i = 0; i < fftLog.avgSize(); i++)
    {
      int w = int(width/fftLog.avgSize());

      x = i*w;
      y = frameCount*5;
      if (!dB)
        z = height/4-fftLog.getAvg(fftLog.avgSize()-i-1)*Amp; //change multiplier to reduces height default '10'
      else{ //convert amplitude to dB scale
        z = (height/4)-(Math.round((Amp-3)*(20*(float)Math.log10(constrain(fftLog.getAvg(fftLog.avgSize()-i-1),cut,50))))*2.0)+(40*(Amp-3)*(float)Math.log10(cut)); //change multiplier to reduces height default '10'
        
      } 
    // println(z); 
      
      stroke(0);
      point(x, y, z);
      pts[i] = new PVector(x, y, z);
      //increase size of array trace by length+1
      trace = (PVector[]) expand(trace, trace.length+1);
      //always get the next to last
      trace[trace.length-1] = new PVector(pts[i].x, pts[i].y, pts[i].z);
    }
  }
  void textdraw()
  {
    if (tex){
    for (int i =round(divi/2); i<fftLog.avgSize(); i=i+round(divi/2)) {
      pushMatrix();  
        if (!altV) {
        translate(pts[i].x, pts[i].y+10, height/4);
        rotateY(PI/2);
        rotateZ(PI/2);  
      }
      else if (altV) {
          translate(pts[i].x, pts[i].y+10, height/4+20);
          rotateZ(PI);
          rotateX(PI*.9);
        }
      
     textFont(font, 15);
     fill(255);
     text(freqs[fftLog.avgSize()-i-1]+" Hz", 0, 0, 0); 
   
      
     popMatrix();
    }
    }
  }
  void plotTrace()
  {
    stroke(255, 80);
    int inc = fftLog.avgSize();
    PVector[] trace2 = new PVector[fftLog.avgSize()*depth];
    if (trace.length > fftLog.avgSize()*depth) {
      arrayCopy(trace, trace.length-(fftLog.avgSize()*depth), trace2, 0, fftLog.avgSize()*depth);
      trace = trace2;
    }
    int cnt = 1;
    for (int i=1; i<trace.length-inc; i++)
    {
      if (i%inc != 0)
      {
        beginShape(TRIANGLE_STRIP);
        strokeWeight(2);
        strokeCap(SQUARE);
        //noStroke();
        float value = (trace[i].z);
        float value2 = (trace[i].x);
        float m = map(value, -10, 179, 150, 0);
        float n = map(value2, 200, 1500, 180, 0);
        float o = map(value2, 200, 1500, 0, 255);
        
        if(fade){
        stroke(255, 255, 255, cnt/3);
        fill(o+m, 100-m/2, n-(m/2), cnt/0.7);
        }
        else{
          stroke(255, 255, 255, 60);
          fill(o+m, 100-m/2, n-(m/2), 180);
        }
        //fill(o, m, n, 150);
        //specular(100, 100, 100);
        //emissive(30,30, 30);
        vertex(trace[i].x, trace[i].y, trace[i].z);
        vertex(trace[i-1].x, trace[i-1].y, trace[i-1].z);
        vertex(trace[i+inc].x, trace[i+inc].y, trace[i+inc].z);
        vertex(trace[i-1+inc].x, trace[i-1+inc].y, trace[i-1+inc].z);
        endShape(CLOSE);
      }
      else
      cnt += 1;
    }
  }
}

void keyPressed() {

  if (key == 'P' || key == 'p') {
    pause = !pause;
  } 
//toggle alternative view
  if (key == 'v' || key == 'V') 
    altV = !altV; 
//toggle dB or linear amplitude
  if (key == 'd' || key == 'D') 
    dB = !dB; 
//toggle fade     
    if (key == 'f' || key == 'F') 
    fade = !fade; 
//toggle text labels   
     if (key == 't' || key == 'T') 
    tex = !tex; 


  if (pause)
    noLoop();
  else
    loop();
}

void stop()
{
  // always close Minim audio classes when you finish with them
  microphone.close();
  // always stop Minim before exiting
  minim.stop();
  super.stop();
}

