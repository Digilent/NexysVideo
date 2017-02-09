#pragma once
#define _CRT_SECURE_NO_WARNINGS

#if defined(WIN32)
	
	/* Include Windows specific headers here.
	*/
	#include <windows.h>
	
#else

	/* Include Unix specific headers here.
	*/
	#include <sys/time.h>
	
#endif
 
#include <string.h>
#include <time.h>
#include <math.h>
#include <fstream>
#include <sstream>
#include <iostream>

#include "dpcdecl.h"
#include "dmgr.h"
#include "dpti.h"

#using <System.dll>

char * send_file_loc = new char [200];
char * receive_file_loc = new char [200];

char    szDevName[cchDvcNameMax + 1];
HIF     hif;
INT32   cprtPti;
DPRP    dprpPti;
INT32   prtReq = 1;
BOOL    fSuccess;
int		ib;
BYTE    bTemp;


namespace DPTI_Transfer {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	using namespace System::IO::Ports;
	using namespace System::Threading;

	using namespace System::Runtime::InteropServices;
	

	/// <summary>
	/// Summary for Form1
	///
	/// WARNING: If you change the name of this class, you will need to change the
	///          'Resource File Name' property for the managed resource compiler tool
	///          associated with all .resx files this class depends on.  Otherwise,
	///          the designers will not be able to interact properly with localized
	///          resources associated with this form.
	/// </summary>
	public ref class Form1 : public System::Windows::Forms::Form
	{
			unsigned char *pBuf1;
			unsigned char *pBuf2;
			unsigned char *dptiLength;
			int fsize, line_index;
			int operation;	
			bool addr_modi_flag, select_file_flag, save_file_flag;
			String^ monitext;
			array<String^>^ lines1;
			array<String^>^ lines2;
			array<String^>^ lines3;
			String^ send_filename;
			String^ receive_filename;
 
	private: System::Windows::Forms::TextBox^  textBox1;
	static bool _continue;
	private: System::Windows::Forms::OpenFileDialog^  openFileDialog1;
	private: System::Windows::Forms::SaveFileDialog^  saveFileDialog1;
	private: System::Windows::Forms::RadioButton^  selectWriteBtn;
	private: System::Windows::Forms::RadioButton^  selectReadBtn;

	private: System::Windows::Forms::Button^  RWBtn;
	private: System::Windows::Forms::TextBox^  AddressBox;
	private: System::Windows::Forms::Label^  AddressLabel;
	private: System::Windows::Forms::TextBox^  LengthBox;
	private: System::Windows::Forms::Label^  LengthLabel;
	private: System::Windows::Forms::TextBox^  TimeBox;

	private: System::Windows::Forms::Label^  TimeLabel;
	private: System::Windows::Forms::TextBox^  MonitorBox1;
	private: System::Windows::Forms::TextBox^  MonitorBox2;
	private: System::Windows::Forms::TextBox^  MonitorBox3;
	private: System::Windows::Forms::Label^  label1;
	private: System::Windows::Forms::Label^  label2;
	private: System::Windows::Forms::Label^  label3;



	private: System::Windows::Forms::TextBox^  DPTItextBox;


	public:
		Form1(void)
		{
			InitializeComponent();
			strcpy(szDevName, "NexysVideo");
			textBox1->Clear();
			DPTItextBox->Clear();
			 
			addr_modi_flag = false;
			save_file_flag = false;
			select_file_flag = false;
			lines1 = gcnew array<String^>(10);
			lines2 = gcnew array<String^>(10);
			lines3 = gcnew array<String^>(10);
			line_index = 0;
			 
			// Setting up the DPTI port  	
			if ( ! DmgrOpen(&hif, szDevName))
			{
				DPTItextBox->Text = "Error 1";
				DPTItextBox->BackColor = System::Drawing::Color::OrangeRed;
			}
					else
					{
						if ( ! DptiGetPortCount(hif, &cprtPti))
						{
							DPTItextBox->Text = "Error 2";
							DPTItextBox->BackColor = System::Drawing::Color::OrangeRed;
						}
						else
						{
							if ( 0 == cprtPti )
							{
								DPTItextBox->Text = "Error 3";
								DPTItextBox->BackColor = System::Drawing::Color::OrangeRed;
							}
							else
							{
								if ( ! DptiGetPortProperties(hif, prtReq, &dprpPti))
								{
									DPTItextBox->Text = "Error 4";
									DPTItextBox->BackColor = System::Drawing::Color::OrangeRed;
								}
								else
									if ( ! DptiEnableEx(hif, prtReq))
									{
										DPTItextBox->Text = "Error 5";
										DPTItextBox->BackColor = System::Drawing::Color::OrangeRed;
									}
									else
									{
										DPTItextBox->Text = "DPTI * ON";
										DPTItextBox->BackColor = System::Drawing::Color::LawnGreen;
									}
							}
						}
					}
			//
			//TODO: Add the constructor code here
			//
		}
	
		// function which converts an int to char (byte) pointer
		unsigned char * UIntToBytePtr (unsigned int Value)
		{
			unsigned char * ptr = new unsigned char [4];
			ptr [3] = (Value >> 24) & 0xFF;
			ptr [2] = (Value >> 16) & 0xFF;
			ptr [1] = (Value >> 8) & 0xFF;
			ptr [0] = Value & 0xFF;
			return ptr;
		}

	protected:
		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		~Form1()
		{
			if (components)
			{
				delete components;
			}
		}
private: System::Windows::Forms::Button^  btnSelectFile;
protected: 

private: System::Windows::Forms::Button^  btnSaveFile;
protected: 

	protected: 

	private:
		/// <summary>
		/// Required designer variable.
		/// </summary>
		System::ComponentModel::Container ^components;
		
#pragma region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		void InitializeComponent(void)
		{
			System::ComponentModel::ComponentResourceManager^  resources = (gcnew System::ComponentModel::ComponentResourceManager(Form1::typeid));
			this->btnSelectFile = (gcnew System::Windows::Forms::Button());
			this->btnSaveFile = (gcnew System::Windows::Forms::Button());
			this->textBox1 = (gcnew System::Windows::Forms::TextBox());
			this->openFileDialog1 = (gcnew System::Windows::Forms::OpenFileDialog());
			this->saveFileDialog1 = (gcnew System::Windows::Forms::SaveFileDialog());
			this->selectWriteBtn = (gcnew System::Windows::Forms::RadioButton());
			this->selectReadBtn = (gcnew System::Windows::Forms::RadioButton());
			this->RWBtn = (gcnew System::Windows::Forms::Button());
			this->AddressBox = (gcnew System::Windows::Forms::TextBox());
			this->AddressLabel = (gcnew System::Windows::Forms::Label());
			this->LengthBox = (gcnew System::Windows::Forms::TextBox());
			this->LengthLabel = (gcnew System::Windows::Forms::Label());
			this->TimeBox = (gcnew System::Windows::Forms::TextBox());
			this->TimeLabel = (gcnew System::Windows::Forms::Label());
			this->DPTItextBox = (gcnew System::Windows::Forms::TextBox());
			this->MonitorBox1 = (gcnew System::Windows::Forms::TextBox());
			this->MonitorBox2 = (gcnew System::Windows::Forms::TextBox());
			this->MonitorBox3 = (gcnew System::Windows::Forms::TextBox());
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->label2 = (gcnew System::Windows::Forms::Label());
			this->label3 = (gcnew System::Windows::Forms::Label());
			this->SuspendLayout();
			// 
			// btnSelectFile
			// 
			this->btnSelectFile->Enabled = false;
			this->btnSelectFile->Location = System::Drawing::Point(10, 139);
			this->btnSelectFile->Name = L"btnSelectFile";
			this->btnSelectFile->Size = System::Drawing::Size(94, 23);
			this->btnSelectFile->TabIndex = 1;
			this->btnSelectFile->Text = L"Select file";
			this->btnSelectFile->UseVisualStyleBackColor = true;
			this->btnSelectFile->Click += gcnew System::EventHandler(this, &Form1::btnSelectFile_Click);
			// 
			// btnSaveFile
			// 
			this->btnSaveFile->Enabled = false;
			this->btnSaveFile->Location = System::Drawing::Point(110, 139);
			this->btnSaveFile->Name = L"btnSaveFile";
			this->btnSaveFile->RightToLeft = System::Windows::Forms::RightToLeft::No;
			this->btnSaveFile->Size = System::Drawing::Size(94, 23);
			this->btnSaveFile->TabIndex = 2;
			this->btnSaveFile->Text = L"Save file as";
			this->btnSaveFile->UseVisualStyleBackColor = true;
			this->btnSaveFile->Click += gcnew System::EventHandler(this, &Form1::btnSaveFile_Click);
			// 
			// textBox1
			// 
			this->textBox1->Location = System::Drawing::Point(10, 197);
			this->textBox1->Name = L"textBox1";
			this->textBox1->ReadOnly = true;
			this->textBox1->Size = System::Drawing::Size(722, 20);
			this->textBox1->TabIndex = 3;
			// 
			// openFileDialog1
			// 
			this->openFileDialog1->FileName = L"openFileDialog1";
			// 
			// selectWriteBtn
			// 
			this->selectWriteBtn->AutoSize = true;
			this->selectWriteBtn->Location = System::Drawing::Point(10, 36);
			this->selectWriteBtn->Name = L"selectWriteBtn";
			this->selectWriteBtn->Size = System::Drawing::Size(101, 17);
			this->selectWriteBtn->TabIndex = 5;
			this->selectWriteBtn->Text = L"Write to memory";
			this->selectWriteBtn->UseVisualStyleBackColor = true;
			this->selectWriteBtn->CheckedChanged += gcnew System::EventHandler(this, &Form1::selectWriteBtn_CheckedChanged);
			// 
			// selectReadBtn
			// 
			this->selectReadBtn->AutoSize = true;
			this->selectReadBtn->Location = System::Drawing::Point(117, 36);
			this->selectReadBtn->Name = L"selectReadBtn";
			this->selectReadBtn->Size = System::Drawing::Size(113, 17);
			this->selectReadBtn->TabIndex = 6;
			this->selectReadBtn->Text = L"Read from memory";
			this->selectReadBtn->UseVisualStyleBackColor = true;
			this->selectReadBtn->CheckedChanged += gcnew System::EventHandler(this, &Form1::selectReadBtn_CheckedChanged);
			// 
			// RWBtn
			// 
			this->RWBtn->Enabled = false;
			this->RWBtn->Location = System::Drawing::Point(10, 168);
			this->RWBtn->Name = L"RWBtn";
			this->RWBtn->Size = System::Drawing::Size(194, 23);
			this->RWBtn->TabIndex = 7;
			this->RWBtn->Text = L"Select operation";
			this->RWBtn->UseVisualStyleBackColor = true;
			this->RWBtn->Click += gcnew System::EventHandler(this, &Form1::RWBtn_Click);
			// 
			// AddressBox
			// 
			this->AddressBox->Font = (gcnew System::Drawing::Font(L"Courier New", 9, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->AddressBox->Location = System::Drawing::Point(12, 59);
			this->AddressBox->Name = L"AddressBox";
			this->AddressBox->ReadOnly = true;
			this->AddressBox->Size = System::Drawing::Size(161, 21);
			this->AddressBox->TabIndex = 8;
			this->AddressBox->TabStop = false;
			this->AddressBox->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			this->AddressBox->TextChanged += gcnew System::EventHandler(this, &Form1::AddressBox_TextChanged);
			// 
			// AddressLabel
			// 
			this->AddressLabel->AutoSize = true;
			this->AddressLabel->Location = System::Drawing::Point(179, 63);
			this->AddressLabel->Name = L"AddressLabel";
			this->AddressLabel->Size = System::Drawing::Size(45, 13);
			this->AddressLabel->TabIndex = 9;
			this->AddressLabel->Text = L"Address";
			// 
			// LengthBox
			// 
			this->LengthBox->Font = (gcnew System::Drawing::Font(L"Courier New", 9));
			this->LengthBox->Location = System::Drawing::Point(13, 86);
			this->LengthBox->Name = L"LengthBox";
			this->LengthBox->ReadOnly = true;
			this->LengthBox->Size = System::Drawing::Size(160, 21);
			this->LengthBox->TabIndex = 10;
			this->LengthBox->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// LengthLabel
			// 
			this->LengthLabel->AutoSize = true;
			this->LengthLabel->Location = System::Drawing::Point(179, 89);
			this->LengthLabel->Name = L"LengthLabel";
			this->LengthLabel->Size = System::Drawing::Size(40, 13);
			this->LengthLabel->TabIndex = 11;
			this->LengthLabel->Text = L"Length";
			// 
			// TimeBox
			// 
			this->TimeBox->Font = (gcnew System::Drawing::Font(L"Courier New", 9));
			this->TimeBox->Location = System::Drawing::Point(12, 112);
			this->TimeBox->Name = L"TimeBox";
			this->TimeBox->ReadOnly = true;
			this->TimeBox->Size = System::Drawing::Size(160, 21);
			this->TimeBox->TabIndex = 12;
			this->TimeBox->TextAlign = System::Windows::Forms::HorizontalAlignment::Right;
			// 
			// TimeLabel
			// 
			this->TimeLabel->AutoSize = true;
			this->TimeLabel->Location = System::Drawing::Point(179, 115);
			this->TimeLabel->Name = L"TimeLabel";
			this->TimeLabel->Size = System::Drawing::Size(70, 13);
			this->TimeLabel->TabIndex = 13;
			this->TimeLabel->Text = L"Time elapsed";
			// 
			// DPTItextBox
			// 
			this->DPTItextBox->Location = System::Drawing::Point(10, 10);
			this->DPTItextBox->Name = L"DPTItextBox";
			this->DPTItextBox->ReadOnly = true;
			this->DPTItextBox->Size = System::Drawing::Size(125, 20);
			this->DPTItextBox->TabIndex = 14;
			this->DPTItextBox->TextAlign = System::Windows::Forms::HorizontalAlignment::Center;
			// 
			// MonitorBox1
			// 
			this->MonitorBox1->AcceptsReturn = true;
			this->MonitorBox1->Font = (gcnew System::Drawing::Font(L"Courier New", 9, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->MonitorBox1->Location = System::Drawing::Point(252, 33);
			this->MonitorBox1->Multiline = true;
			this->MonitorBox1->Name = L"MonitorBox1";
			this->MonitorBox1->ReadOnly = true;
			this->MonitorBox1->Size = System::Drawing::Size(141, 158);
			this->MonitorBox1->TabIndex = 15;
			// 
			// MonitorBox2
			// 
			this->MonitorBox2->AcceptsReturn = true;
			this->MonitorBox2->Font = (gcnew System::Drawing::Font(L"Courier New", 9, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->MonitorBox2->Location = System::Drawing::Point(399, 33);
			this->MonitorBox2->Multiline = true;
			this->MonitorBox2->Name = L"MonitorBox2";
			this->MonitorBox2->ReadOnly = true;
			this->MonitorBox2->Size = System::Drawing::Size(111, 158);
			this->MonitorBox2->TabIndex = 16;
			// 
			// MonitorBox3
			// 
			this->MonitorBox3->AcceptsReturn = true;
			this->MonitorBox3->Font = (gcnew System::Drawing::Font(L"Courier New", 9, System::Drawing::FontStyle::Regular, System::Drawing::GraphicsUnit::Point, 
				static_cast<System::Byte>(0)));
			this->MonitorBox3->Location = System::Drawing::Point(516, 33);
			this->MonitorBox3->Multiline = true;
			this->MonitorBox3->Name = L"MonitorBox3";
			this->MonitorBox3->ReadOnly = true;
			this->MonitorBox3->Size = System::Drawing::Size(216, 158);
			this->MonitorBox3->TabIndex = 17;
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(249, 17);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(53, 13);
			this->label1->TabIndex = 18;
			this->label1->Text = L"Operation";
			// 
			// label2
			// 
			this->label2->AutoSize = true;
			this->label2->Location = System::Drawing::Point(396, 17);
			this->label2->Name = L"label2";
			this->label2->Size = System::Drawing::Size(84, 13);
			this->label2->TabIndex = 19;
			this->label2->Text = L"Number of bytes";
			// 
			// label3
			// 
			this->label3->AutoSize = true;
			this->label3->Location = System::Drawing::Point(513, 17);
			this->label3->Name = L"label3";
			this->label3->Size = System::Drawing::Size(52, 13);
			this->label3->TabIndex = 20;
			this->label3->Text = L"File name";
			// 
			// Form1
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(747, 230);
			this->Controls->Add(this->label3);
			this->Controls->Add(this->label2);
			this->Controls->Add(this->label1);
			this->Controls->Add(this->MonitorBox3);
			this->Controls->Add(this->MonitorBox2);
			this->Controls->Add(this->MonitorBox1);
			this->Controls->Add(this->DPTItextBox);
			this->Controls->Add(this->TimeLabel);
			this->Controls->Add(this->TimeBox);
			this->Controls->Add(this->LengthLabel);
			this->Controls->Add(this->LengthBox);
			this->Controls->Add(this->AddressLabel);
			this->Controls->Add(this->AddressBox);
			this->Controls->Add(this->RWBtn);
			this->Controls->Add(this->selectReadBtn);
			this->Controls->Add(this->selectWriteBtn);
			this->Controls->Add(this->textBox1);
			this->Controls->Add(this->btnSaveFile);
			this->Controls->Add(this->btnSelectFile);
			this->Icon = (cli::safe_cast<System::Drawing::Icon^  >(resources->GetObject(L"$this.Icon")));
			this->Name = L"Form1";
			this->Text = L"DPTI Transfer";
			this->FormClosed += gcnew System::Windows::Forms::FormClosedEventHandler(this, &Form1::Form1_FormClosed);
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion

// Select File button	
private: System::Void btnSelectFile_Click(System::Object^  sender, System::EventArgs^  e) 
		 {	
			 int i,j;
			 DPTItextBox->Clear();
			
			 // Starting the open file dialog
			 OpenFileDialog ^ openFileDialog1 = gcnew OpenFileDialog();

			 if (openFileDialog1->ShowDialog() == System::Windows::Forms::DialogResult::OK)
			 {		
				 // Getting the Filename and Path
				 send_filename = System::IO::Path::GetFileName(openFileDialog1->FileName); 
				 String^ send_path = System::IO::Path::GetDirectoryName(openFileDialog1->FileName); 

				 //Converting to char and creating a single char array which contains both the filename and its path
				 for (i = 0; i < send_path->Length; i++)
				 {
					 send_file_loc[i] = (char)Convert::ToChar(send_path[i]);
				 }
				 send_file_loc[i] = 0x5c; // Adding a backslash
				 for (j = 0; j < send_filename->Length; j++)
				 {
					 send_file_loc[j+i+1] = (char)Convert::ToChar(send_filename[j]);
				 }

				 send_file_loc[j+i+1] = 0;

				 // Converting to string so that we can display in the Text Box
				 String^ str_send_file_loc = gcnew String(send_file_loc);

				 textBox1->Text = str_send_file_loc;
	 
				 // Enabling the RW button
				 if (addr_modi_flag)
					 RWBtn->Enabled = true;
				 else
					 save_file_flag = true;

				}

		 }
	
private: System::Void btnSaveFile_Click(System::Object^  sender, System::EventArgs^  e) 
		 {
			 
			 int i,j;

			 DPTItextBox->Clear();

			 SaveFileDialog ^ saveFileDialog1 = gcnew SaveFileDialog();
			 // Starting the save file dialog			
			 saveFileDialog1->ShowDialog();
				
			 if(saveFileDialog1->FileName != "")
			 {
				 //getting the file name
				 receive_filename = System::IO::Path::GetFileName(saveFileDialog1->FileName); 
				 // getting the path to the file location
				 String^ receive_path = System::IO::Path::GetDirectoryName(saveFileDialog1->FileName); 
				 
				 //converting to char
				 for (i = 0; i < receive_path->Length; i++)
				 {
					 receive_file_loc[i] = (char)Convert::ToChar(receive_path[i]); 
				 }
				 receive_file_loc[i] = 0x5c; // adding a backslash
				 for (j = 0; j < receive_filename->Length; j++)
				 {
					 receive_file_loc[j+i+1] = (char)Convert::ToChar(receive_filename[j]);
				 }
				 receive_file_loc[j+i+1] = 0;

				 String^ str_receive_file_loc = gcnew String(receive_file_loc);

				 textBox1->Text = str_receive_file_loc;
				
				 // enabling the RW button
				 if (addr_modi_flag)
					 RWBtn->Enabled = true;
				 else
					 select_file_flag = true;
				 
			 }
				 
	 
		 }

		 // when closing the application the DPTI port must be disabled
private: System::Void Form1_FormClosed(System::Object^  sender, System::Windows::Forms::FormClosedEventArgs^  e) 
		 {
			 if ( hifInvalid != hif ) 
			 {
				 DptiDisable(hif);
				 DmgrClose(hif);
			 }
 		 }

		 // Radio button handlers
		 // Write operation selected
private: System::Void selectWriteBtn_CheckedChanged(System::Object^  sender, System::EventArgs^  e) 
		 {
			 operation = 1; // writing to DPTI
			 RWBtn->Text =  "Write data";
			 // clearing textboxes
			 TimeBox->Clear();
			 LengthBox->Clear();
			 AddressBox->Clear();
			
			 // Addressbox is only enabled after we select an operation
			 AddressBox->ReadOnly = false;
			 // Lengthbox is only enabled for write operations 
			 LengthBox->ReadOnly = true;
			 // a file can only be selected when writing
			 btnSelectFile->Enabled = true;
			 // a file can only be saved when reading
			 btnSaveFile->Enabled = false;
		 }

		 // Read operation selected
private: System::Void selectReadBtn_CheckedChanged(System::Object^  sender, System::EventArgs^  e) 
		 {
			 operation = 2; // reading from DPTI
			 RWBtn->Text =  "Read data";
			 // clearing textboxes
			 TimeBox->Clear();
			 LengthBox->Clear();
			 AddressBox->Clear();

			 // Addressbox is only enabled after we select an operation
			 AddressBox->ReadOnly = false;
			 // Lengthbox is only enabled for write operations
			 LengthBox->ReadOnly = false;
			 // a file can only be selected when writing
			 btnSelectFile->Enabled = false;
			 // a file can only be saved when reading
			 btnSaveFile->Enabled = true;
			  
		 }

private: System::Void RWBtn_Click(System::Object^  sender, System::EventArgs^  e) 
		 {
			 // when pressing the RW button the transfer is started
			 LARGE_INTEGER start, end, frequency;
			 double  trateBps, trateKBps, trateMBps, sec;
			 std::stringstream sstr;
			 unsigned char *hex_addr_to_send;

			 // the destination/source address is read from the designated textbox
			 String^ Address_from_TB = AddressBox->Text;
			 // the address is verified 
			 bool AddressNULL = Address_from_TB == nullptr || Address_from_TB == String::Empty;

			 if (!AddressNULL)
			 {
				 // parsing the string received from the address text box so that it will be interpreted 
				 // as an actual hexadecimal value 
				 array<Byte> ^ Addr_chars = System::Text::Encoding::ASCII->GetBytes(Address_from_TB);
				 pin_ptr<Byte> Addr_charsPointer = &(Addr_chars[0]);
				 char *Addr_nativeCharsPointer = reinterpret_cast<char *>(static_cast<unsigned char *>(Addr_charsPointer));
				 std::string Addr_std_str(Addr_nativeCharsPointer, Addr_chars->Length);

				 sstr << Addr_std_str;
				 unsigned int HEX_ADDRESS;
				 // converting int to hex
				 sstr >> std::hex >> HEX_ADDRESS;
			  
				 char text_fsize [30];
				 //writing to char array
				 sprintf(text_fsize,"0x%08X", HEX_ADDRESS);

				 // converting to byte pointer
				 hex_addr_to_send = UIntToBytePtr (HEX_ADDRESS);
				 // saving the address in order to have it displayed later as history
				 lines1 [line_index] = AddressBox->Text;
			 }
 
			 if (operation == 1)  // we have selected to write to DPTI
			 {
				 unsigned char *operation_to_send = new unsigned char [4];
				 operation_to_send = UIntToBytePtr (operation);
				 // the file selected earlier is opened
				 FILE *file_to_send = fopen(send_file_loc, "rb");
				 fseek(file_to_send,0,SEEK_END);
				 // file size is determined
				 fsize = ftell(file_to_send);
				 // memory is alocated for the file
				 pBuf1 = (BYTE*)malloc(sizeof(BYTE) * fsize);
				 fseek(file_to_send,0,SEEK_SET);
				 // the file's contents are converted to byte pointer
				 fread(pBuf1, 1, fsize, file_to_send);
				 // file is closed
				 fclose(file_to_send);
				 // the value indicating the file size is converted to byte pointer
				 unsigned char *length_to_send = new unsigned char [4];
				 length_to_send = UIntToBytePtr (fsize);
 
				 // the file size is converted to system string 
				 char text_fsize [30];
				 sprintf(text_fsize,"%d",fsize);
				 String^ str_fsize = gcnew String(text_fsize);
				 // fsize is displayed in LengthBox
				 LengthBox->Text = str_fsize;
			     
				 // DPTI transfers are being performed
				 
				 // DPTI header is sent first in predetermined order
				 // fsize is sent 
				 fSuccess = DptiIO(hif, length_to_send, 4, NULL, NULL, fFalse);
				 // destination address is sent
				 fSuccess = DptiIO(hif, hex_addr_to_send, 4, NULL, NULL, fFalse);
				 // the operation code is sent
				 fSuccess = DptiIO(hif, operation_to_send, 4, NULL, NULL, fFalse);
				 
				 // the selected file is sent
				 // the transfer speed is calculated
				 QueryPerformanceFrequency(&frequency);
				 QueryPerformanceCounter(&start);

				 fSuccess = DptiIO(hif, pBuf1, fsize, NULL, NULL, fFalse);

				 QueryPerformanceCounter(&end);

				 sec = double(end.QuadPart - start.QuadPart) / frequency.QuadPart;
		
			     trateBps = (double)fsize / sec;	 
				 trateKBps = trateBps / 1024.0;
				 trateMBps = trateKBps / 1024.0;
				 
				 // values are converted to string and displayed in text box
				 float roundSec = floorf((float)sec * 100) / 100;
			     String^ StrSec = Convert::ToString (roundSec);
				
				 float roundRateMB = floorf((float)trateMBps * 100) / 100;
				 String^ StrRateMB = Convert::ToString (roundRateMB);

				 TimeBox->Text = StrSec + "s" + " @ " + StrRateMB + " MB/s"; 		 

				 // the file DPTI transfer is validated 
				 if(fSuccess)
				 {
					 DPTItextBox->BackColor = System::Drawing::Color::LawnGreen;
					 DPTItextBox->Text = "Upload Completed";
					 // in this case a "Write" operation was performed. lines1 also contains the destination address
					 lines1[line_index] = "Write" + "\t" + lines1[line_index];
				 }
				 else
				 {
					 DPTItextBox->Text = "Upload Failed";
					 DPTItextBox->BackColor = System::Drawing::Color::OrangeRed;
					 lines1[line_index] = "WFail" + "\t" + lines1[line_index];
				 }

				 // the other transfer parameters are prepared for display
				 // transfer size  
				 lines2[line_index] = System::Convert::ToString(fsize);
				 // file name  
				 lines3[line_index] = System::Convert::ToString(send_filename);  

				 if (line_index < 10)
					 line_index++;
				 else
					 line_index = 0;
				// data is displayed
				MonitorBox1->Lines = lines1;	
				MonitorBox2->Lines = lines2;	
				MonitorBox3->Lines = lines3;
				
				// since the transfer was finalized the data allocated for the file must be freed
				 if ( NULL != pBuf1 )  
				 {
					 free(pBuf1);
				 }
			 }

			 else 
				 if (operation == 2) // we have selected to read from DPTI
				 {
					 // local declarations
					 unsigned int read_length;
					 unsigned char *length_to_send = new unsigned char [4];

					 unsigned char *operation_to_send = new unsigned char [4];
					 // memory is allocated for the file size which will be received
					 dptiLength = (BYTE*)calloc(4, sizeof(BYTE));
					 // the operation value is converted to byte pointer
					 operation_to_send = UIntToBytePtr (operation);
					 // the location and filename of the new file to be written is converted 
					 String^ str_receive_file_loc = gcnew String(receive_file_loc);
					 // the user must enter the transfer size in bytes
					 String^ Length_from_TB = LengthBox->Text;
					 // the value is then verified
					 bool LengthNULL = Length_from_TB == nullptr || Length_from_TB == String::Empty;

					 if (!LengthNULL)
					 {
						 // the length value is converted to byte pointer
						 read_length = Convert::ToUInt32 (Length_from_TB);
						 length_to_send = UIntToBytePtr (read_length);
					 }

					 // DPTI transfers are being performed

					 // DPTI header is sent first in predetermined order
					 // transfer size is sent
					 fSuccess = DptiIO(hif, length_to_send, 4, NULL, NULL, fFalse);
					 // source address is sent
					 fSuccess = DptiIO(hif, hex_addr_to_send, 4, NULL, NULL, fFalse);
					 // the operation code is sent
					 fSuccess = DptiIO(hif, operation_to_send, 4, NULL, NULL, fFalse);
 
					 // memory is alocated for the file which will be received
					 pBuf2 = (BYTE*)calloc(read_length, sizeof(BYTE));

					 // the selected file is received
					 // the transfer speed is calculated
					 QueryPerformanceFrequency(&frequency);
					 QueryPerformanceCounter(&start);

					 fSuccess = DptiIO(hif, NULL, NULL, pBuf2, read_length, fFalse);

					 QueryPerformanceCounter(&end);

					 sec = double(end.QuadPart - start.QuadPart) / frequency.QuadPart;
			
					 trateBps = (double)read_length / sec;	 
					 trateKBps = trateBps / 1024.0;
					 trateMBps = trateKBps / 1024.0;
					 
					 // values are converted to string and displayed in text box
					 float roundSec = floorf((float)sec * 100) / 100;
					 String^ StrSec = Convert::ToString (roundSec);
					 float roundRateMB = floorf((float)trateMBps * 100) / 100;
					 String^ StrRateMB = Convert::ToString (roundRateMB);
					 TimeBox->Text = StrSec + "s" + " @ " + StrRateMB + " MB/s"; 		 

					 // DPTI file transfer is validated
					 if(fSuccess)
					 {
						 DPTItextBox->BackColor = System::Drawing::Color::LawnGreen;
						 DPTItextBox->Text = "Download Completed";
						 // if the transfer succeded the new file is created using the location and filename provided by the user
						 FILE *file_to_receive = fopen(receive_file_loc , "wb" );
						 fwrite(pBuf2, 1 , read_length , file_to_receive );
						 // file is closed
						 fclose(file_to_receive);
						 // in this case a "Read" operation was performed. lines1 also contains the address
						 lines1[line_index] = "Read" + "\t" + lines1[line_index];
					 }
					 else
					 {
						 DPTItextBox->Text = "Download Failed";
						 DPTItextBox->BackColor = System::Drawing::Color::OrangeRed;
						 lines1[line_index] = "RFail" + "\t" + lines1[line_index];
					 }

					 // the other transfer parameters are prepared for display
					 // transfer size 
					 lines2[line_index] = System::Convert::ToString(read_length);
					 // file name
					 lines3[line_index] = System::Convert::ToString(receive_filename);
					  					  
					 if (line_index < 10)
						 line_index++;
					 else
						 line_index = 0;

					// data is displayed
					MonitorBox1->Lines = lines1;	
					MonitorBox2->Lines = lines2;	
					MonitorBox3->Lines = lines3;	

					// since the transfer was finalized the data allocated for the file must be freed
					 if ( NULL != pBuf2 ) 
					 {
						 free(pBuf2);
					 }
					 if ( NULL != dptiLength ) 
					 {
						 free(dptiLength);
					 }
				 }

				 // RW button is disabled
				 RWBtn->Enabled = false;
				 // flags reset
				 select_file_flag = false;
				 save_file_flag = false;
 
		 }
private: System::Void AddressBox_TextChanged(System::Object^  sender, System::EventArgs^  e) {

			 // in order for the RW button to be enabled, new data must be written into the address
			 // text box and either a file must be selected to be sent or a new file name and location
			 // must be provided for data to be written to
			 if (select_file_flag || save_file_flag)
				 RWBtn->Enabled = true;
			 else
				 addr_modi_flag = true;

		 }
};

}


