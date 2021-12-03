#include once "inc/sound.bi"
#include once "file.bi"

#define AUDIO_DEFAULT_SAMPLE_VOLUME    0.5
#define AUDIO_DEFAULT_MUSIC_VOLUME     0.5

#define AUDIO_RATE      MIX_DEFAULT_FREQUENCY
#define AUDIO_FORMAT    MIX_DEFAULT_FORMAT
#define AUDIO_MONO      1
#define AUDIO_STEREO    2
#define AUDIO_BUFFERS   1024


type AliasType
    file as string
    aka as string
end type

type SampleType
    
    id as integer
	isRepeating as boolean
	
    chunk as Mix_Chunk ptr
	volume as ubyte
	maxChannels as ubyte
	activeChannels as ubyte
    
end type


declare function Sound_AllocSample () as SampleType ptr
declare function Sound_FindSample (id as integer) as SampleType ptr
declare sub      Sound_ChannelFinished cdecl(cid as integer)
declare sub      Sound_ResetGlobals()

redim shared as SampleType  Samples(any)
redim shared as AliasType   SampleAliases(any)
redim shared as AliasType   MusicAliases(any)

dim shared as SampleType ptr Channels(15)
dim shared as Mix_Music ptr  MusicPTR
dim shared as string         SamplesPath
dim shared as string         MusicPath
dim shared as double         SamplesVolume
dim shared as double         MusicVolume
dim shared as boolean        SystemIsInitialized
dim shared as boolean        SystemIsMuted
dim shared as boolean        MusicIsRepeating


sub Sound_Init (samplesPath as string = "", musicPath as string = "")
    
    Sound_ResetGlobals
    
    if samplesPath <> "" then Sound_SetSamplesPath samplesPath
    if musicPath   <> "" then Sound_SetMusicPath musicPath
    
	if Mix_OpenAudio( AUDIO_RATE, AUDIO_FORMAT, AUDIO_STEREO, AUDIO_BUFFERS ) then
		exit sub
	end if
	
	if (Mix_Init( MIX_INIT_OGG ) and MIX_INIT_OGG) <> MIX_INIT_OGG then
		exit sub
	end if
	
	Mix_AllocateChannels(ubound(Channels)+1)
	dim n as integer
	for n = 0 to ubound(Channels)
		Channels(n) = 0
	next n
	Mix_ChannelFinished(@Sound_ChannelFinished)
	
	SystemIsInitialized = 1
    
end sub

sub Sound_ResetGlobals()
    
    MusicPTR            = 0
    SamplesPath         = ""
    MusicPath           = ""
    SamplesVolume       = AUDIO_DEFAULT_SAMPLE_VOLUME
    MusicVolume         = AUDIO_DEFAULT_MUSIC_VOLUME
    SystemIsInitialized = 0
    SystemIsMuted       = 0
    MusicIsRepeating    = 0
    
    erase Channels
    erase Samples
    erase SampleAliases
    erase MusicAliases
    
end sub

sub Sound_FreeSamples()
    
    dim as SampleType ptr sample
    dim as integer n
    
    for n = 0 to ubound(Channels)
        Mix_HaltChannel n
    next n
    
	for n = 0 to ubound(Samples)
        sample = @Samples(n)
        if sample andalso sample->chunk then
            Mix_FreeChunk( sample->chunk ): sample->chunk = 0
        end if
	next n
    
    erase Samples
    erase Channels
    
end sub

sub Sound_Release ()
    
	if SystemIsInitialized then
        if MusicPTR then Mix_FreeMusic( MusicPTR ): MusicPTR = 0
        Sound_FreeSamples
        Sound_ResetGlobals
		Mix_CloseAudio
        Mix_Quit
	end if
    
end sub

sub Sound_SetSamplesPath( path as string )
    if path <> "" then
        if right( path, 1 ) <> "/" then path += "/"
        SamplesPath = path
    end if
end sub

sub Sound_SetMusicPath( path as string )
    if path <> "" then
        if right( path, 1 ) <> "/" then path += "/"
        MusicPath = path
    end if
end sub

sub Sound_MuteSound
    
    SystemIsMuted = 1
    
end sub

sub Sound_UnmuteSound
    
    SystemIsMuted = 0
    
end sub

sub Sound_SetMusicVolume(volume as double)
    
	if SystemIsInitialized then
		Mix_VolumeMusic(volume*MIX_MAX_VOLUME)
		MusicVolume = volume
	end if
    
end sub

sub Sound_SetSamplesVolume(volume as double)
    
    dim as SampleType ptr sample
    dim as integer n
    
	if SystemIsInitialized then
		for n = 0 to ubound(Samples)
            sample = @Samples(n)
            if sample andalso sample->chunk then
			    Mix_VolumeChunk(sample->chunk, volume*sample->volume)
            end if
		next n
		SamplesVolume = volume
	end if
    
end sub

function Sound_GetMusicVolume() as double
	return MusicVolume
end function

function Sound_GetSamplesVolume() as double
	return SamplesVolume
end function

function Sound_FindSample (id as integer) as SampleType ptr

	dim n as integer
	for n = 0 to ubound(Samples)
		if Samples(n).id = id then
			return @Samples(n)
		end if
	next n
	
	return 0
	
end function

sub Sound_SetMusic (byval filename as string, isRepeating as integer = 1)
	
    filename = MusicPath + Sound_GetMusicFileByAlias(filename)
    if FileExists(filename) = 0 then exit sub
    
	if trim(filename) = "" then
		Sound_StopMusic
		MusicPTR = 0
	else
		MusicPTR = Mix_LoadMUS(filename)
        MusicIsRepeating = isRepeating
	end if
    
end sub

sub Sound_PlayMusic ()
    
	if SystemIsInitialized and (MusicPTR <> 0) then
		Mix_VolumeMusic( MusicVolume*MIX_MAX_VOLUME )
		Mix_PlayMusic( MusicPTR, iif(MusicIsRepeating,-1,0) )
	end if
    
end sub

sub Sound_StopMusic ()
    
	if SystemIsInitialized then
		Mix_HaltMusic
	end if
    
end sub

sub Sound_PauseMusic ()
    
	if SystemIsInitialized and (MusicPTR <> 0) then
		if Mix_PlayingMusic then
			Mix_PauseMusic
		end if
	end if
    
end sub

sub Sound_ResumeMusic ()
    
	if SystemIsInitialized and (MusicPTR <> 0) then
		Mix_ResumeMusic() '- safe to use despite music status
	end if
    
end sub

sub Sound_FadeInMusic (seconds as double = 3.0)
    
    dim as integer ms = int(seconds * 1000)
    
    Mix_FadeInMusic( MusicPTR, MusicIsRepeating, ms )
    
end sub

sub Sound_FadeOutMusic (seconds as double = 3.0)
    
    dim as integer ms = int(seconds * 1000)
    
    Mix_FadeOutMusic( ms )
    
end sub

function Sound_MusicIsFading () as integer
    
    return Mix_FadingMusic() <> MIX_NO_FADING
    
end function

function Sound_MusicIsPlaying () as integer
    
	return (Mix_PlayingMusic() = 1) and (Mix_PausedMusic() = 0)
    
end function

function Sound_AllocSample () as SampleType ptr
    
    dim as SampleType ptr sample
    dim as integer i, n
    
    n = ubound(Samples) + 1: redim preserve Samples(n)
    
    '- sample ptrs from channels() might become invalidated (if
    '- samples() array needs to be moved to new block of memory to
    '- accommodate the new size), so reassign them here
    for i = 0 to ubound(Channels)
        sample = Channels(i)
        Channels(i) = iif(sample, Sound_FindSample(sample->id), 0)
    next i
    
    return @Samples(n)
    
end function

sub Sound_LoadSample (id as integer, byval filename as string, volume as double=1.0, isRepeating as boolean=0, maxChannels as integer=4)
    
    if SystemIsInitialized = 0 then exit sub
    if Sound_FindSample(id) then exit sub
    if trim(filename) = "" then exit sub
    if maxChannels <= 0 then exit sub
    
    filename = SamplesPath + SOUND_GetSampleFileByAlias(filename)
    if FileExists(filename) = 0 then exit sub
    
    dim as SampleType ptr sample = Sound_AllocSample()
    
    if sample then
        
        if maxChannels > ubound(Channels) then maxChannels = ubound(Channels)
        
        if volume > 1.0 then volume = 1.0
        if volume < 0.0 then volume = 0.0
        
        sample->chunk          = Mix_LoadWAV(filename)
        sample->id             = id
        sample->isRepeating    = isRepeating
        sample->volume         = int(volume*MIX_MAX_VOLUME)
        sample->maxChannels    = iif(maxChannels > 4, 4, maxChannels)
        sample->activeChannels = 0
        
        if sample->chunk then
            Mix_VolumeChunk(sample->chunk, int(SamplesVolume*sample->volume))
        end if
        
    end if
    
end sub

sub Sound_UpdateSample (id as integer, volume as double=-1, isRepeating as integer=-1, maxChannels as integer=-1)
    
    dim as SampleType ptr sample = Sound_FindSample(id)
    
    if sample then
        if volume >= 0 and volume <> sample->volume then
            sample->volume = volume
            Mix_VolumeChunk(sample->chunk, int(SamplesVolume*sample->volume))
        end if
        if isRepeating > -1 then sample->isRepeating = isRepeating
        if maxChannels > -1 then sample->maxChannels = maxChannels
    end if
    
end sub

sub Sound_UnloadSample (id as integer)
    
    dim as SampleType ptr sample = Sound_FindSample(id)
    dim as integer i, j
    
    if sample then
        Sound_StopSample id
        if sample->chunk then Mix_FreeChunk(sample->chunk): sample->chunk = 0
        for i = 0 to ubound(Samples)
		    if Samples(i).id = sample->id then
			    
                if ubound(Samples) > 0 then
                    for j = i to ubound(Samples)-1
                        Samples(j) = Samples(j+1)
                    next j
                    redim preserve Samples(ubound(Samples)-1)
                else
                    erase Samples
                end if
                
                exit for
                
		    end if
        next i
    end if
    
end sub

sub Sound_PlaySample (id as integer)

	if SystemIsInitialized = 0 then exit sub
    if SystemIsMuted then exit sub
    
    dim as SampleType ptr sample
    dim as integer cid
    
    sample = Sound_FindSample(id)
    if sample andalso sample->activeChannels < sample->maxChannels then
        
        cid = Mix_PlayChannel(-1, sample->chunk, iif(sample->isRepeating,-1,0))
        if cid <> -1 then
            if Channels(cid) = 0 then
                Channels(cid) = sample
                sample->activeChannels += 1
            end if
        end if
	end if
	
end sub

sub Sound_PauseSample (id as integer)
    
	if SystemIsInitialized = 0 then return
    
    dim as SampleType ptr sample
    dim as integer n
    
    for n = 0 to ubound(Channels)
        sample = Channels(n)
        if sample andalso sample->id = id then
            Mix_Pause(n)
        end if
    next n
	
end sub

sub Sound_ResumeSample (id as integer)
    
    if SystemIsInitialized = 0 then return
    
    dim as SampleType ptr sample
    dim as integer n
    
    for n = 0 to ubound(Channels)
        sample = Channels(n)
        if sample andalso sample->id = id then
            Mix_Resume(n)
        end if
    next n
    
end sub

sub Sound_PauseAllSamples ()
    Mix_Pause( -1 )
end sub

sub Sound_ResumeAllSamples ()
    Mix_Resume( -1 )
end sub

sub Sound_StopSample (id as integer)
    
	if SystemIsInitialized = 0 then return
    
    dim as SampleType ptr sample
    dim as integer n
    
    for n = 0 to ubound(Channels)
        sample = Channels(n)
        if sample andalso sample->id = id then
            Mix_HaltChannel(n)
            sample->activeChannels -= 1
        end if
    next n
	
end sub

sub Sound_StopAllSamples ()
	
	if SystemIsInitialized = 0 then return
	
    dim as SampleType ptr sample
    dim as integer n
    
    for n = 0 to ubound(Channels)
        sample = Channels(n)
        if sample then
            Mix_HaltChannel(n)
            sample->activeChannels -= 1
        end if
    next n
	
end sub

sub Sound_ChannelFinished cdecl(cid as integer)
    	
	if SystemIsInitialized = 0 then return
	
    dim as SampleType ptr sample = Channels(cid)
    
    if sample then
        sample->activeChannels -= 1
	end if
	
	Channels(cid) = 0
	
end sub

sub Sound_AddAliasForSampleFile(file as string, aka as string)
    
    dim as integer n = ubound( SampleAliases ) + 1
    
    redim preserve SampleAliases( n )
    SampleAliases( n ).file = file
    SampleAliases( n ).aka = aka
    
end sub

function Sound_GetSampleFileByAlias(aka as string) as string
    
    dim as integer n
    
    for n = 0 to ubound( SampleAliases )
        if SampleAliases( n ).aka = aka then
            return SampleAliases( n ).file
        end if
    next n
    
    return aka
    
end function

sub Sound_AddAliasForMusicFile(file as string, aka as string)
    
    dim as integer n = ubound( MusicAliases ) + 1
    
    redim preserve MusicAliases( n )
    MusicAliases( n ).file = file
    MusicAliases( n ).aka = aka
    
end sub

function Sound_GetMusicFileByAlias(aka as string) as string
    
    dim as integer n
    
    for n = 0 to ubound( MusicAliases )
        if MusicAliases( n ).aka = aka then
            return MusicAliases( n ).file
        end if
    next n
    
    return aka
    
end function
