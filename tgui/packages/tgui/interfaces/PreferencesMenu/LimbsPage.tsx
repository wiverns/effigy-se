import { useBackend } from '../../backend';
import {
  Box,
  Button,
  ColorBox,
  Dropdown,
  Section,
  Stack,
} from '../../components';
import { CharacterPreview } from '../common/CharacterPreview';
import { PreferencesMenuData } from './data';

const Gap = (props: { amount: number }) => {
  // 0.2em comes from the padding-bottom in the department listing
  return <Box height={`calc(${props.amount}px + 0.2em)`} />;
};

export const RotateCharacterButtons = (props) => {
  const { act } = useBackend<PreferencesMenuData>();
  return (
    <Box mt={1}>
      <Button
        onClick={() => act('rotate', { backwards: false })}
        fontSize="22px"
        icon="redo"
        tooltip="Rotate Clockwise"
        tooltipPosition="bottom"
      />
      <Button
        onClick={() => act('rotate', { backwards: true })}
        fontSize="22px"
        icon="undo"
        tooltip="Rotate Counter-Clockwise"
        tooltipPosition="bottom"
      />
    </Box>
  );
};

export const Markings = (props) => {
  const { act } = useBackend<PreferencesMenuData>();
  return (
    <Stack fill vertical>
      <Stack.Item>Markings:</Stack.Item>
      {props.limb.markings.markings_list.map((marking, index) => (
        <Stack.Item key={marking.marking_id}>
          <Stack fill>
            <Stack.Item grow>
              <Dropdown
                width="100%"
                options={props.limb.markings.marking_choices}
                displayText={marking.name}
                onSelected={(shit) =>
                  act('change_marking', {
                    limb_slot: props.limb.slot,
                    marking_id: marking.marking_id,
                    marking_name: shit,
                  })
                }
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                fill
                onClick={() =>
                  act('color_marking', {
                    limb_slot: props.limb.slot,
                    marking_id: marking.marking_id,
                  })
                }
              >
                <ColorBox color={marking.color} />
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                fill
                color={marking.emissive ? 'good' : 'bad'}
                tooltip="The 'E' is for 'Emissive', meaning does it glow or not. Green for glow, red for no glow."
                onClick={() =>
                  act('change_emissive', {
                    limb_slot: props.limb.slot,
                    marking_id: marking.marking_id,
                    emissive: marking.emissive,
                  })
                }
              >
                E
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                fill
                color="bad"
                onClick={() =>
                  act('remove_marking', {
                    limb_slot: props.limb.slot,
                    marking_id: marking.marking_id,
                  })
                }
              >
                -
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      ))}
      <Stack.Item>
        <Button
          fill
          color="good"
          onClick={() => act('add_marking', { limb_slot: props.limb.slot })}
        >
          +
        </Button>
      </Stack.Item>
    </Stack>
  );
};

export const LimbPage = (props) => {
  const { act } = useBackend<PreferencesMenuData>();
  return (
    <div>
      <Section fill title={props.limb.name}>
        <Stack vertical fill>
          <Stack.Item>
            <Markings limb={props.limb} />
          </Stack.Item>
        </Stack>
      </Section>
    </div>
  );
};

export const AugmentationPage = (props) => {
  const { act } = useBackend<PreferencesMenuData>();
  const { data } = useBackend<PreferencesMenuData>();
  let balance = -data.quirks_balance;
  if (props.limb.can_augment) {
    return (
      <div style={{ marginBottom: '1.5em' }}>
        <Section fill title={props.limb.name}>
          <Stack fill vertical>
            <Stack.Item>
              <Stack fill>
                <Stack.Item>Augumentation:</Stack.Item>
                <Stack.Item grow>
                  <Dropdown
                    grow
                    width="100%"
                    options={Object.values(props.limb.aug_choices) as string[]}
                    displayText={props.limb.chosen_aug}
                    onSelected={(value) => {
                      // Since the costs are positive,
                      // it's added and not substracted
                      if (balance + props.limb.costs[value] > 0) {
                        return;
                      }
                      act('set_limb_aug', {
                        limb_slot: props.limb.slot,
                        augment_name: value,
                      });
                    }}
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Stack fill vertical>
                <Stack.Item>Style:</Stack.Item>
                <Stack.Item grow>
                  <Dropdown
                    grow
                    width="100%"
                    options={props.data.robotic_styles}
                    displayText={props.limb.chosen_style}
                    onSelected={(value) =>
                      act('set_limb_aug_style', {
                        limb_slot: props.limb.slot,
                        style_name: value,
                      })
                    }
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </div>
    );
  }
  return null;
};

export const OrganPage = (props) => {
  const { act } = useBackend<PreferencesMenuData>();
  const { data } = useBackend<PreferencesMenuData>();
  let balance = -data.quirks_balance;
  return (
    <Stack.Item>
      <Stack fill>
        <Stack.Item>{props.organ.name + ': '}</Stack.Item>
        <Stack.Item grow>
          <Dropdown
            width="100%"
            options={Object.values(props.organ.organ_choices) as string[]}
            displayText={props.organ.chosen_organ}
            onSelected={(value) => {
              // Since the costs are positive, it's added and not substracted
              if (balance + props.organ.costs[value] > 0) {
                return;
              }
              act('set_organ_aug', {
                organ_slot: props.organ.slot,
                augment_name: value,
              });
            }}
          />
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};

export const LimbsPage = () => {
  const { data } = useBackend<PreferencesMenuData>();
  const { act } = useBackend<PreferencesMenuData>();
  const markings = data.marking_presets ? data.marking_presets : [];
  let balance = -data.quirks_balance;
  return (
    <Stack minHeight="100%">
      <Stack.Item minWidth="33%" minHeight="100%">
        <Section fill scrollable title="Markings" height="222%">
          <div>
            <Dropdown
              grow
              width="100%"
              options={Object.values(markings)}
              displayText="Pick a preset:"
              onSelected={(value) => act('set_preset', { preset: value })}
            />
          </div>
          <div>
            {data.limbs_data.map((val) => (
              <LimbPage key={val.slot} limb={val} data={data} />
            ))}
          </div>
        </Section>
      </Stack.Item>
      <Stack.Item minWidth="33%">
        <Section title="Character Preview" fill align="center" height="222%">
          <CharacterPreview
            id={data.character_preview_view}
            height="25%"
            width="100%"
          />
          <RotateCharacterButtons />
          <Gap amount={50} />
          <Box
            style={{
              marginTop: '3em',
            }}
          >
            <Section title="Quirk Points" />
          </Box>

          <Box
            backgroundColor="#eee"
            bold
            color="black"
            fontSize="1.2em"
            py={0.5}
            style={{
              width: '20%',
              alignItems: 'center',
            }}
          >
            {balance}
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item minWidth="33%">
        <Section fill title="Organs" height="87%">
          <Stack fill vertical>
            {data.organs_data.map((val) => (
              <OrganPage key={val.slot} organ={val} data={data} />
            ))}
          </Stack>
        </Section>
        <Section fill scrollable title="Augmentations" height="132.5%">
          {data.limbs_data.map((val) => (
            <AugmentationPage key={val.slot} limb={val} data={data} />
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};
