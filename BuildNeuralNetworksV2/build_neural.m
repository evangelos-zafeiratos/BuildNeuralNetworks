function varargout = build_neural(varargin)
% build_neural MATLAB code for build_neural.fig
%      build_neural, by itself, creates a new build_neural or raises the existing
%      singleton*.
%
%      H = build_neural returns the handle to a new build_neural or the handle to
%      the existing singleton*.
%
%      build_neural('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in build_neural.M with the given input arguments.
%
%      build_neural('Property','Value',...) creates a new build_neural or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before build_neural_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to build_neural_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help build_neural

% Last Modified by GUIDE v2.5 12-Nov-2014 00:43:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @build_neural_OpeningFcn, ...
                   'gui_OutputFcn',  @build_neural_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before build_neural is made visible.
function build_neural_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to build_neural (see VARARGIN)

% Choose default command line output for build_neural
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% create an axes that spans the whole gui
ah = axes('unit', 'normalized', 'position', [0 0 1 1]); 
% import the background image and show it on the axes
bg = imread('Images\neural.jpg'); imagesc(bg);
% prevent plotting over the background and turn the axis off
set(ah,'handlevisibility','off','visible','off')
% making sure the background is behind all the other uicontrols
uistack(ah, 'bottom');

% Create an axes to host Title
ah = axes('unit', 'normalized', 'position', [0 0 1 1]); 
h = text(0.22,0.89,'BUILD NEURAL NETWORK','FontSize',26,'FontWeight','Bold','Color',[0 0 0]);
axis off;

% UIWAIT makes build_neural wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = build_neural_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in InsertFiles.
function InsertFiles_Callback(hObject, eventdata, handles)
% hObject    handle to InsertFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load the training data file
[No_RTS, Rows_train, No_Outputs, No_Scenarios, initial_path, train_file] = load_and_read_train();

% Load the validation data file
[Rows_validation, val_file]                                              = load_and_read_validation();

% Calculate the sum of RTSs
Rows_total = Rows_train + Rows_validation;


% ---------------------------------------------------------------------------------
% The next lines of code describe an algorithm which estimates the wanted number of
% hidden nodes. 
variable1 = No_Scenarios*2 + round(No_Outputs*1.5) + No_RTS;
variable2 = No_Scenarios*2 + round(No_Outputs*1.5) + No_RTS + round(Rows_train/500);
if (Rows_train/variable1) > 50 
    category = 1;
else
    category = 2;
end;
if (variable2 < 40)
    if category == 1
        rec = round(Rows_train/100);
    else
        rec = round(Rows_train/200);
    end;
else if (variable2 < 60)
        if category == 1
            rec = round(Rows_train/80);
        else
            rec = round(Rows_train/140);
        end;
    else if (variable2 < 80)
            if category == 1
                rec = round(Rows_train/60);
            else 
                rec = round(Rows_train/110);
            end;
        else if (variable2 < 100)
                if category == 1
                    rec = round(Rows_train/40);
                else
                    rec = round(Rows_train/60);
                end;
            else
                if category == 1
                    rec = round(Rows_train/30);
                else 
                    rec = round(Rows_train/45);
                end;
            end;
        end;
    end;
end;
% ---------------------------------------------------------------------------

% Print the neural networks basic elements in GUI

No_RTS_string = num2str(No_RTS);
set(handles.Inputs,'String',No_RTS_string);

No_Outputs_string = num2str(No_Outputs);
set(handles.Outputs,'String',No_Outputs_string);

Rows_total_string = num2str(Rows_total);
set(handles.Cases,'String',Rows_total_string);

No_Scenarios_srgin = num2str(No_Scenarios);
set(handles.No_Scenarios,'String',No_Scenarios_srgin);

recommendation = num2str(rec);
set(handles.recommendation,'String',recommendation);

% Use this pointer in order to maintain instant access to the "message"
% text field
pointer = handles.message;

% The usage of this 'data' structure is to transfer values among different
% fucntions of the GUI. Each element of the structure is defined and 
% sometimes is instantiated with an initial value.

% Concatenate matrixes
full_file = [train_file ; val_file];



% The following structure transfers data among functions. We use initial
% values for some of them. Brief explanation of struct fields:
% Data   { dataset         : The concatenated matrix of both train and
%                            validation data
%          origunal_path   : The initial Matlab path
%          hidden_nodes    : User defined hidden nodes of Ann
%          mul_style       : User defined choice of multiplication style
%          precision       : User defined choice of bits precision
%          act_function    : User defined choice of activation function
%          CLK             : User defined choice of CLK edge
%          switch_criteria : Optional user choice which determines the
%                            criteria under which a change in Scenario is 
%                            triggered
%          enable_criteria : This field is set to '1' only when optional
%                            switch_criteria is defined.
%          message_pointer : Stored pointer to instantly access specific
%                            text field
%          LUT_select      : User defined choice of LUT implementation
%          No_Scenarios    : Data determined number of Scenarios
%          No_training     : Optional user choice that allows to pass
%                            values to Complementary LUTs
%          No_train_enable : This field is set to '1' only when optional
%                            No_training is defined.
%          instances       : User defined number of ANN instantiations
%          tFrame          : Not used


% Create the structure with some initial values, and store it into guidata
% handler

data = struct('dataset',full_file,'original_path',initial_path,'hidden_nodes',' ','mul_style',' ',...
              'precision',' ', 'act_function',' ','CLK',' ','switch_criteria',' ','enable_criteria','0',...
              'message_pointer',pointer, 'LUT_select',' ','No_Scenarios',No_Scenarios,...
              'No_training',' ','No_train_enable','0','instances',' ','tFrame',' ',...
              'Train_rows',Rows_train,'Val_rows',Rows_validation);
guidata(hObject,data);



function Inputs_Callback(hObject, eventdata, handles)
% hObject    handle to Inputs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Inputs as text
%        str2double(get(hObject,'String')) returns contents of Inputs as a double


% --- Executes during object creation, after setting all properties.
function Inputs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Inputs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Outputs_Callback(hObject, eventdata, handles)
% hObject    handle to Outputs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Outputs as text
%        str2double(get(hObject,'String')) returns contents of Outputs as a double


% --- Executes during object creation, after setting all properties.
function Outputs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Outputs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Cases_Callback(hObject, eventdata, handles)
% hObject    handle to Cases (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Cases as text
%        str2double(get(hObject,'String')) returns contents of Cases as a double


% --- Executes during object creation, after setting all properties.
function Cases_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Cases (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Hidden_Callback(hObject, eventdata, handles)
% hObject    handle to Hidden (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Hidden as text
%        str2double(get(hObject,'String')) returns contents of Hidden as a double

% Get the input value of hidden nodes - convert into num
hidden_neurons = str2double(get(hObject,'String'));

% Use temp data variable to update the field of data guidata structure
data              = guidata(hObject);
data.hidden_nodes = hidden_neurons;
guidata(hObject,data);


% --- Executes during object creation, after setting all properties.
function Hidden_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Hidden (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on selection change in mul_style.
function mul_style_Callback(hObject, eventdata, handles)
% hObject    handle to mul_style (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns mul_style contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mul_style

% Get the input value of mul_style
mul_style_menu = cellstr(get(hObject,'String'));
multiplication = mul_style_menu{get(hObject,'Value')};

% Use temp data variable to update the field of data guidata structure
data           = guidata(hObject);
data.mul_style = multiplication;
guidata(hObject,data);


% --- Executes during object creation, after setting all properties.
function mul_style_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mul_style (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Precision.
function Precision_Callback(hObject, eventdata, handles)
% hObject    handle to Precision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns Precision contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Precision

% Get the input value of precision bits
precision_menu  = cellstr(get(hObject,'String'));
level_precision = precision_menu{get(hObject,'Value')};

% Use temp data variable to update the field of data guidata structure
data           = guidata(hObject);
data.precision = level_precision;
guidata(hObject,data);

% --- Executes during object creation, after setting all properties.
function Precision_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Precision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in act_function.
function act_function_Callback(hObject, eventdata, handles)
% hObject    handle to act_function (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns act_function contents as cell array
%        contents{get(hObject,'Value')} returns selected item from act_function

% Get the input value of activation function
act_function_menu = cellstr(get(hObject,'String'));
sel_function      = act_function_menu{get(hObject,'Value')};

% Use temp data variable to update the field of data guidata structure
data              = guidata(hObject);
data.act_function = sel_function;
guidata(hObject,data);


% --- Executes during object creation, after setting all properties.
function act_function_CreateFcn(hObject, eventdata, handles)
% hObject    handle to act_function (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in CLK_trigger.
function CLK_trigger_Callback(hObject, eventdata, handles)
% hObject    handle to CLK_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns CLK_trigger contents as cell array
%        contents{get(hObject,'Value')} returns selected item from CLK_trigger

% Get the input value of CLK triggering edge
CLK_trig_menu = cellstr(get(hObject,'String'));
CLK_trigger   = CLK_trig_menu{get(hObject,'Value')};

% Use temp data variable to update the field of data guidata structure
data          = guidata(hObject);
data.CLK      = CLK_trigger;
guidata(hObject,data);



% --- Executes during object creation, after setting all properties.
function CLK_trigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CLK_trigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Build.
function Build_Callback(hObject, eventdata, handles)
% hObject    handle to Build (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Build button is the final action in GUI when all settings have been
% defined. A function call triggers nntoolbox, which trains the selected
% neural networks for all specifications made by user.

data = guidata(hObject);

% Print a message to a proper text field to declare processing
set(data.message_pointer,'String','Processing');
train_and_print(data);

% Print a message to a proper text field to declare uccesful outcome
set(data.message_pointer,'String','Succesful!');


% --- Executes on button press in switch_button.
function switch_button_Callback(hObject, eventdata, handles)
% hObject    handle to switch_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data                 = guidata(hObject);
Scenarios            = data.No_Scenarios;

% Asks for a dat file that contains info about Scenario switching
[filename, pathname] = uigetfile({'*.dat'},'File Selector'); 

% Stores the full path of the file in this variable 
file_path            = strcat(pathname,filename);  

% Stores the values within the data file in this matrix (full_matrix)
switch_file          = dlmread(file_path);  

% Call of "create_string" function" with operands the input file and
% Scenarios. This function will print a VHDL expression to evaluate the
% conditions when we do not change Scenarios
[switch_string]      = create_string(switch_file,Scenarios);

% Update the equivalent guidata structure fields
data.switch_criteria = switch_string;
data.enable_criteria = 1;
guidata(hObject,data);


function No_Scenarios_Callback(hObject, eventdata, handles)
% hObject    handle to No_Scenarios (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of No_Scenarios as text
%        str2double(get(hObject,'String')) returns contents of No_Scenarios as a double


% --- Executes during object creation, after setting all properties.
function No_Scenarios_CreateFcn(hObject, eventdata, handles)
% hObject    handle to No_Scenarios (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function recommendation_Callback(hObject, eventdata, handles)
% hObject    handle to recommendation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of recommendation as text
%        str2double(get(hObject,'String')) returns contents of recommendation as a double


% --- Executes during object creation, after setting all properties.
function recommendation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to recommendation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function message_Callback(hObject, eventdata, handles)
% hObject    handle to message (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of message as text
%        str2double(get(hObject,'String')) returns contents of message as a double


% --- Executes during object creation, after setting all properties.
function message_CreateFcn(hObject, eventdata, handles)
% hObject    handle to message (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in LUT_select.
function LUT_select_Callback(hObject, eventdata, handles)
% hObject    handle to LUT_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns LUT_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LUT_select

% Get the input value of Lut implementation style
LUT_selection_menu = cellstr(get(hObject,'String'));
LUT_selection      = LUT_selection_menu{get(hObject,'Value')};

% Use temp data variable to update the field of data guidata structure
data               = guidata(hObject);
data.LUT_select    = LUT_selection;
guidata(hObject,data);



% --- Executes during object creation, after setting all properties.
function LUT_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LUT_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in NoTraining.
function NoTraining_Callback(hObject, eventdata, handles)
% hObject    handle to NoTraining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


data                 = guidata(hObject);

% Asks for a dat file that contains the optional non-training data
[filename, pathname] = uigetfile({'*.dat'},'File Selector'); 

% Stores the full path of the file in this variable 
file_path            = strcat(pathname,filename);            
No_train_values      = load(file_path);

% Use temp data variable to update the field of data guidata structure
data.No_training     = No_train_values;
data.No_train_enable = 1;
guidata(hObject,data);



function instantiations_Callback(hObject, eventdata, handles)
% hObject    handle to instantiations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of instantiations as text
%        str2double(get(hObject,'String')) returns contents of instantiations as a double

% Store the number of instantiated Neural Networks
instances = str2double(get(hObject,'String'));
data = guidata(hObject);

% Use temp data variable to update the field of data guidata structure
data.instances = instances;
guidata(hObject,data);


% --- Executes during object creation, after setting all properties.
function instantiations_CreateFcn(hObject, eventdata, handles)
% hObject    handle to instantiations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function timeFrame_Callback(hObject, eventdata, handles)
% hObject    handle to timeFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeFrame as text
%        str2double(get(hObject,'String')) returns contents of timeFrame as a double

% NOT USED in this editions
tFrames = str2double(get(hObject,'String'));
data = guidata(hObject);
data.tFrame = tFrames;
guidata(hObject,data);


% --- Executes during object creation, after setting all properties.
function timeFrame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
