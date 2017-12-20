-module(lsb).
-export([load/2, save/3, add_text_to_image/2, filter_byte_chars/1]).
-export([main/1]).
-define(EOF, [0]).
-compile(export_all).

-record(image, {
    width = 0,
    height = 0,
    contents,
    headers
}).

load(jpeg, _FileName) -> {error, not_implemented};
load(png, _FileName) -> {error, not_implemented};
load(bmp, FileName) ->
    case file:read_file(FileName) of
        {ok, Contents} -> parse_contents(Contents);
        SomethingElse  -> SomethingElse
    end.

save(bmp, FileName, ImageData) ->
    file:write_file(FileName, ImageData).
    
parse_contents(Contents) ->
    case Contents of
        <<"BM",_:64,Off:32/little,_:32,
            Width:32/signed-little,
            Height:32/signed-little,
            _Rest/binary>>
                        ->
                        Headers = binary_part(Contents,0,Off),
                        PixelDataSize = size(Contents)-Off,
                        io:fwrite("Head size: ~p, cont.size: ~p~n~n", [size(Headers), PixelDataSize]),
                        PixelData = binary_part(Contents,Off,PixelDataSize),
                        Image = #image{
                            width = Width,
                            height = Height,
                            headers = Headers,
                            contents = PixelData
                        },
                        {ok, Image}
                        ;
                        
        _               -> {error, wrong_format}
    end.

filter_byte_chars([]) ->
    [];
filter_byte_chars([CurrentChar | Rest]) ->
    if
        CurrentChar < 256 ->
            [CurrentChar | filter_byte_chars(Rest)];
        true ->
            filter_byte_chars(Rest)
    end.

add_text_to_image(Image, Text) ->
    NewContent = add_text_to_image_impl(<<>>, Image#image.contents, unicode:characters_to_binary(lists:append(Text, ?EOF))),
    Headers = Image#image.headers,
    <<Headers/bitstring, NewContent/bitstring>>.

add_text_to_image_impl(NewContent, <<>>, RestTextBinary) ->
    NewContent;
add_text_to_image_impl(NewContent, RestImageContent, <<>>) ->
    <<NewContent/binary, RestImageContent/binary>>;
add_text_to_image_impl(NewContent, <<RestImageContent:1/binary>>, RestTextBinary) ->
	<<NewContent/binary, RestImageContent/binary>>;
add_text_to_image_impl(NewContent, <<B:1/binary, G:1/binary, R:1/binary, RestImageContent/binary>>,
                       <<TextChar:1/binary, RestTextBinary/binary>>) ->
    <<CharPart1:3/bitstring, CharPart2:3/bitstring, CharPart3:2/bitstring>> = TextChar,
    <<BMainPart:5/bitstring, _:3/bitstring>> = B,
    <<GMainPart:5/bitstring, _:3/bitstring>> = G,
    <<RMainPart:6/bitstring, _:2/bitstring>> = R,
    NewPixel = <<BMainPart/bitstring, CharPart1/bitstring,
                 GMainPart/bitstring, CharPart2/bitstring,
                 RMainPart/bitstring, CharPart3/bitstring>>,
    add_text_to_image_impl(<<NewContent/binary, NewPixel/binary>>, RestImageContent, RestTextBinary).

get_text_from_image(Image) ->
    get_text_from_image_impl(<<>>, Image#image.contents).
    
get_text_from_image_impl(DecodedText, <<>>) ->
    binary_to_list(DecodedText);
get_text_from_image_impl(DecodedText, <<RestImageContent:1/binary>>) ->
	binary_to_list(DecodedText);
get_text_from_image_impl(DecodedText, <<B:1/binary, G:1/binary, R:1/binary, RestImageContent/binary>>) ->
    <<_:5/bitstring, CharPart1:3/bitstring>> = B,
    <<_:5/bitstring, CharPart2:3/bitstring>> = G,
    <<_:6/bitstring, CharPart3:2/bitstring>> = R,
    TextChar = <<CharPart1/bitstring, CharPart2/bitstring, CharPart3/bitstring>>,
    TextCharAsList = binary_to_list(TextChar),
    if
        TextCharAsList =:= ?EOF ->
            binary_to_list(DecodedText);
        true ->
            get_text_from_image_impl(<<DecodedText/binary, TextChar/binary>>, RestImageContent)
    end.
    

main([SourceFileName, DestinationFileName, Text | _ ]) ->
    io:format("Source text: \"~ts\"~n", [unicode:characters_to_binary(Text)]),
    FilteresText = filter_byte_chars(Text),
    io:format("Filtered text: ~p~n~n", [FilteresText]),

    {ok, Image} = load(bmp, SourceFileName),

    NewImageData = add_text_to_image(Image, FilteresText),
    save(bmp, DestinationFileName, NewImageData),

    {ok, NewImage} = parse_contents(NewImageData),
    
    io:fwrite("Decoded text: \"~ts\"~n", [get_text_from_image(NewImage)]).

