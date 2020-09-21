%% Comments
%{  
    - whitespace does not matter in MATLAB, you can indent however you want
    - semicolons are typically not required, they just suppress output
    - type "help <function>" in the Command Window for documentation
%}

clc         % clear the Command Window history
clearvars   % clear all variables from the Workspace
close all   % close all figure windows

%% Arrays
% all numbers are double-precision arrays by default

a = 8;  two_pi = 2*pi;  % multiple commands per line are allowed
print_fun(two_pi)       % custom function defined below

row_vec = -1:2:3;       % row vector from -1 to 3 in increments of 2
x = linspace(-2,4,16);  % 16 points linearly spaced from -2 and 4

y1 = zeros(size(x));    % an array of 0's the same size as x
y2 = ones(size(x));     % an array of 1's the same size as x

% creates a 3x16 array of random numbers in the range (0,1)
matrix = rand([3,length(x)]);
matrix_T = matrix.';    % transpose (no . for complex conjugate transpose)

% matrix multiplication:
matrix_mult = matrix*matrix_T;  % (3x16) * (16x3) = (3,3)

% a period means element-wise array operations
elem_mult = x.*y2;      % (1x16) arrays
elem_pow = x.^2;

[X,Y] = meshgrid(x,x'); % create 2D matrices from 1D vectors
Z = math_fun(X,Y);      % custom function defined below

avg = mean(matrix(:));  % (:) converts the multi-dim array to 1D vector
stdev = std(matrix);    % standard deviation of each matrix column

%% Loops

% for loop
for i = 1:a
    % arrays are indexed starting at 1 (not 0)
    y1(i) = sqrt(i);  % square root
end
% the index variable i still exists and now has the same value as a

% while loop
while i > 0
    y1(a+i) = 3.5;
    i = i - 1;
end

%% Figures

figure  % creates a new figure
set(gcf,'color','w')  % sets background color of the current figure

subplot(1,2,1)  % creates subplots: 1 row and 2 columns of plots
hold on % plotting multiple things
line1 = plot(x,elem_pow,'k-');
line2 = errorbar(x,y1,avg*y2,2*stdev,'rs');  % data points with error bars
line3 = plot(x,y2,'b:','LineWidth',2);
hold off % done plotting
xlim([-2,3]), ylim([0,6])  % sets the axis limits
legend([line1,line2,line3],...  % continuing on the next line...
    {'solid black','red squares','blue dotted'},'Location','NorthWest')
% MATLAB can recognize Greek characters in strings:
xlabel('X-Axis default font'), ylabel('lambda = \lambda')
% labels and titles can also use LaTeX formatting
title('LaTeX Title: $x^{2} = \frac{\pi}{2}$','Interpreter','Latex')

subplot(1,2,2), hold on  % switching to the second subplot
contourf(X,Y,Z)  % filled contour plot
% pass a matrix to plot multiple datasets together:
pts = plot(row_vec,matrix_mult-4,'wo--',...  % could also use scatter(x,y)
    'MarkerFaceColor','r','MarkerSize',6);
hold off
axis equal  % makes the x & y axes the same scale
cbar = colorbar;  ylabel(cbar,'contour levels')  % color scale
xlabel('X-Axis large font'), ylabel('Y-Axis'), title('Plot Title')
% sets font size and line thickness of the current axis:
set(gca,'FontSize',16,'LineWidth',2)

%% Functions
% these functions only exist inside this script:
% they cannot be called from other scripts or the command window

function result = math_fun(a,b)
    % the variable a from the script does not exist inside this function
    result = (a+1).^2 + 3*b.^2;
end

% this function shows how to print numbers to the command window
function [] = print_fun(num)
    disp(num)
    fprintf('Printing an integer: %d\n',round(num))
    fprintf('Printing 8 decimal places: %16.8f\n',num)
    fprintf('Printing in scientific notation: %E\n',num)
    fprintf('Printing as a string: %s\n',num2str(num))
end
